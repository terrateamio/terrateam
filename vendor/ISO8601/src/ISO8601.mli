(** {2 ISO 8601 and RFC 3339 parsing and printing} *)

(** Version 0.2.5 *)

module Permissive : sig

    (** {2 Date parsing}

        [date], [time] and [datetime] parse a [string] and return the
        corresponding timestamp (as [float]).

        Times are {b always} converted to UTC representation.

        For each of these functions, a [_lex] suffixed function read
        from a [Lexing.lexbuf] instead of a [string].

        [datetime] functions also take an optional boolean [reqtime]
        indicating if parsing must fail if a date is given and not
        a complete datetime. (Default is true).

        Functions with [_tz] in their name return a [float * float option]
        representing [timestamp * offset option (timezone)]. [timestamp]
        will be the UTC time, and [offset option] is just an information
        about the original timezone.
     *)

    val date_lex : Lexing.lexbuf -> float
    val date : string -> float

    val time_tz_lex : Lexing.lexbuf -> (float * float option)
    val time_lex : Lexing.lexbuf -> float
    val time_tz : string -> (float * float option)
    val time : string -> float

    val datetime_tz_lex : ?reqtime:bool -> Lexing.lexbuf -> (float * float option)
    val datetime_lex : ?reqtime:bool -> Lexing.lexbuf -> float
    val datetime_tz : ?reqtime:bool -> string -> (float * float option)
    val datetime : ?reqtime:bool -> string -> float

    (** {2 Printing functions}

        {b NB: fractionnal part of timestamps will be lost when printing
         with current implementation.}

     *)

    (** [pp_format fmt format x tz]

        [x] is the timestamp, and [tz] the time zone offset.

        The [format] string is a character string which contains
        two types of objects: plain characters, which are simply copied
        to [fmt], and conversion specifications, each of which causes
        conversion and printing of (a part of) [x] or [tz].

        {b If you do not want to use a timezone, set it to 0.}

        Conversion specifications have the form [%X], where X can be:

        - [Y]: Year
        - [M]: Month
        - [D]: Day
        - [h]: Hours
        - [m]: Minutes
        - [s]: Seconds
        - [Z]: Hours of [tz] offset (with its sign)
        - [z]: Minutes of [tz] offset (without sign)
        - [%]: The '%' character

     *)
    val pp_format : Format.formatter -> string -> float -> float -> unit

    (** "%Y-%M-%D" format. *)
    val pp_date : Format.formatter -> float -> unit
    val string_of_date : float -> string

    (** "%Y%M%D" format. *)
    val pp_date_basic : Format.formatter -> float -> unit
    val string_of_date_basic : float -> string

    (** "%h:%m:%s" format. *)
    val pp_time : Format.formatter -> float -> unit
    val string_of_time : float -> string

    (** "%h%m%s" format. *)
    val pp_time_basic : Format.formatter -> float -> unit
    val string_of_time_basic : float -> string

    (** "%Y-%M-%DT%h:%m:%s" format. *)
    val pp_datetime : Format.formatter -> float -> unit
    val string_of_datetime : float -> string

    (** "%Y%M%DT%h%m%s" format. *)
    val pp_datetime_basic : Format.formatter -> float -> unit
    val string_of_datetime_basic : float -> string

    (** "%Y-%M-%DT%h:%m:%s%Z:%z" format. *)
    val pp_datetimezone : Format.formatter -> (float * float) -> unit
    val string_of_datetimezone : (float * float) -> string

    (** "%Y%M%DT%h%m%s%Z%z" format. *)
    val pp_datetimezone_basic : Format.formatter -> (float * float) -> unit
    val string_of_datetimezone_basic : (float * float) -> string

end
