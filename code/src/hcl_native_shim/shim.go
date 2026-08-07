// sg_hcl_shim is a long-lived stdio daemon that parses HCL using
// hashicorp/hcl/v2's native parser and emits a JSON-encoded AST back to
// the caller. It exists because calling Go c-archive libraries from
// non-Go processes on Alpine musl is broken due to an initial-exec-TLS
// incompatibility; spawning a plain Go subprocess sidesteps that
// entirely.
//
// Wire protocol (both directions, length-prefixed, big-endian):
//
//	Request:
//	  uint32 n                 (covers op byte + source bytes)
//	  uint8  op                (0 = file, 1 = expression, 2 = template)
//	  n-1 bytes of HCL source (UTF-8)
//	Response:
//	  uint32 m
//	  uint8  status            (0 = ok, 1 = error)
//	  m-1 bytes payload
//	    - on ok for op=0: Hcl_parser_value.t list    (JSON array)
//	    - on ok for op=1: Hcl_parser_value.Expr.t     (JSON)
//	    - on ok for op=2: Hcl_parser_value.Template_part.t list (JSON array)
//	    - on error:       plain-text diagnostics
//
// One request/response per connection turn; the daemon loops forever on
// stdin until EOF or an unrecoverable I/O error. Panics are contained: a
// panic in a handler becomes an error response, not a process exit.
package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"io"
	"os"
)

const (
	statusOk  = byte(0)
	statusErr = byte(1)

	opParseFile       = byte(0)
	opParseExpression = byte(1)
	opParseTemplate   = byte(2)

	// maxRequestBytes caps request size to prevent a malformed length from
	// causing the daemon to allocate unbounded memory.
	maxRequestBytes = 256 * 1024 * 1024 // 256 MiB
)

func main() {
	in := bufio.NewReader(os.Stdin)
	out := bufio.NewWriter(os.Stdout)
	for {
		if err := handleOne(in, out); err != nil {
			if err == io.EOF {
				return
			}
			fmt.Fprintf(os.Stderr, "sg_hcl_shim: fatal: %v\n", err)
			os.Exit(1)
		}
	}
}

func handleOne(in *bufio.Reader, out *bufio.Writer) error {
	var hdr [4]byte
	if _, err := io.ReadFull(in, hdr[:]); err != nil {
		return err
	}
	n := binary.BigEndian.Uint32(hdr[:])
	if n < 1 {
		return fmt.Errorf("request too small: %d bytes", n)
	}
	if n > maxRequestBytes {
		return fmt.Errorf("request too large: %d bytes", n)
	}
	opBuf := [1]byte{}
	if _, err := io.ReadFull(in, opBuf[:]); err != nil {
		return err
	}
	src := make([]byte, n-1)
	if _, err := io.ReadFull(in, src); err != nil {
		return err
	}

	status, payload := handleRequest(opBuf[0], src)
	return writeResponse(out, status, payload)
}

// handleRequest dispatches by op byte, under a recover guard so a panic
// anywhere in the parse/encode path becomes an error response.
func handleRequest(op byte, src []byte) (status byte, payload []byte) {
	defer func() {
		if r := recover(); r != nil {
			status = statusErr
			payload = []byte(fmt.Sprintf("sg_hcl_shim: panic: %v", r))
		}
	}()
	switch op {
	case opParseFile:
		return parseFileToJSON(src)
	case opParseExpression:
		return parseExpressionToJSON(src)
	case opParseTemplate:
		return parseTemplateToJSON(src)
	default:
		return statusErr, []byte(fmt.Sprintf("sg_hcl_shim: unknown op byte %d", op))
	}
}

func writeResponse(out *bufio.Writer, status byte, payload []byte) error {
	// Length field covers the status byte plus the payload.
	n := uint32(len(payload) + 1)
	var hdr [4]byte
	binary.BigEndian.PutUint32(hdr[:], n)
	if _, err := out.Write(hdr[:]); err != nil {
		return err
	}
	if err := out.WriteByte(status); err != nil {
		return err
	}
	if _, err := out.Write(payload); err != nil {
		return err
	}
	return out.Flush()
}
