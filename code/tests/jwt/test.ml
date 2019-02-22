let jwt = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjdkNjgwZDhjNzBkNDRlOTQ3MTMzY2JkNDk5ZWJjMWE2MWMzZDVhYmMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiMTA1MDg3NTI2ODYwNi05ZmlnMGdpYjBxaDM4ZmZyZ3Y4bTFyamZtZHFqc2NpaS5hcHBzLmdvb2dsZXVzZXJjb250ZW50LmNvbSIsImF1ZCI6IjEwNTA4NzUyNjg2MDYtOWZpZzBnaWIwcWgzOGZmcmd2OG0xcmpmbWRxanNjaWkuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDU5MjUyNDQ3OTczNTMxOTg4NDMiLCJlbWFpbCI6Im1tYXRhbGthQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoidnF0eExPUXNNMDRKcDBxMmxjQmU1dyIsIm5hbWUiOiJNYWxjb2xtIE1hbHVya2EiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDUuZ29vZ2xldXNlcmNvbnRlbnQuY29tLy1tM0hHRm8xQnk0by9BQUFBQUFBQUFBSS9BQUFBQUFBQUFFMC9pS1p0UThtTXMzQS9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiTWFsY29sbSIsImZhbWlseV9uYW1lIjoiTWFsdXJrYSIsImxvY2FsZSI6ImVuLUdCIiwiaWF0IjoxNTUwNTE0MTIyLCJleHAiOjE1NTA1MTc3MjIsImp0aSI6IjU3ODI4MmViN2QzZjQwNmQ1NjMyNmFkMzFlYTJmODVmODNkOWI1ZDgifQ.vcF9xydjFJRyjE8j9ljZP-TNWBWYZhYAurMKxIXT67SqgMDfGQrons2PgogMNsynIsEOCvSJFANrkDkSZR4eubAn7F1lYjXfR_1--gcRyuMOff1H4BfoxWrNyHlN5B9S9UBoBTXVLnbbQLrz1CJ6i23KA-IEtGk_aV1LEFpR34J4ugBdNZ-_FheZwxdTsM8oZAW4_bjP5aiIzJPKrYf-cQ7PWTi6q6OuhFi0VmjL8bF_dScGKwcoB38yxD2Z4dulE3WCFUyDpG9E7jKNiPiHn0qlPDvDTY7wRc6nkqc6uvxN99ZMkOo-UC7XmKn0h4QcvZNnF42w4BDdCMZ0-wDnZA"

let e = "AQAB"
let n = "2K7epoJWl_B68lRUi1txaa0kEuIK4WHiHpi1yC4kPyu48d046yLlrwuvbQMbog2YTOZdVoG1D4zlWKHuVY00O80U1ocFmBl3fKVrUMakvHru0C0mAcEUQo7ItyEX7rpOVYtxlrVk6G8PY4EK61EB-Xe35P0zb2AMZn7Tvm9-tLcccqYlrYBO4SWOwd5uBSqc_WcNJXgnQ-9sYEZ0JUMhKZelEMrpX72hslmduiz-LMsXCnbS7jDGcUuSjHXVLM9tb1SQynx5Xz9xyGeN4rQLnFIKvgwpiqnvLpbMo6grhJwrz67d1X6MwpKtAcqZ2V2v4rQsjbblNH7GzF8ZsfOaqw"

let basic_jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
let basic_secret = "your-256-bit-secret"

let test_decode =
  Oth.test
    ~desc:"Decode JWT"
    ~name:"Decode"
    (fun _ ->
       assert (None <> Jwt.of_token jwt))

let test_algo =
  Oth.test
    ~desc:"Verify algorithm"
    ~name:"Algo"
    (fun _ ->
       let t = CCOpt.get_exn (Jwt.of_token jwt) in
       let header = Jwt.header t in
       assert ("RS256" = Jwt.Header.algorithm header))

let test_kid =
  Oth.test
    ~desc:"kid matches expected kid"
    ~name:"kid match"
    (fun _ ->
       let t = CCOpt.get_exn (Jwt.of_token jwt) in
       let header = Jwt.header t in
       let kid = CCOpt.get_exn (Jwt.Header.get "kid" header) in
       assert ("7d680d8c70d44e947133cbd499ebc1a61c3d5abc" = kid))

let test_verify =
  Oth.test
    ~desc:"Verify signature"
    ~name:"Verify signature"
    (fun _ ->
       let t = CCOpt.get_exn (Jwt.of_token jwt) in
       let pub_key = CCOpt.get_exn (Jwt.Verifier.Pub_key.create ~e ~n) in
       let verifier = Jwt.Verifier.RS256 pub_key in
       let verified = Jwt.verify verifier t in
       assert (None <> verified))

let test_basic_decode =
  Oth.test
    ~desc:"Decode Basic JWT"
    ~name:"Decode basic"
    (fun _ ->
       assert (None <> Jwt.of_token basic_jwt))

let test_basic_verify =
  Oth.test
    ~desc:"Verify basic signature"
    ~name:"Verify basic signature"
    (fun _ ->
       let t = CCOpt.get_exn (Jwt.of_token basic_jwt) in
       let verifier = Jwt.Verifier.HS256 basic_secret in
       let verified = Jwt.verify verifier t in
       assert (None <> verified))

let test =
  Oth.parallel
    [ test_decode
    ; test_algo
    ; test_kid
    ; test_verify
    ; test_basic_decode
    ; test_basic_verify
    ]

let () =
  Random.self_init ();
  Oth.run test
