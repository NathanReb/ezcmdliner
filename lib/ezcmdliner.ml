open Cmdliner

type 'a conv = 'a Arg.conv

type spec
type final

type ('a, 'b) arg =
  | Spec : 'a * 'a Arg.t -> ('a, spec) arg
  | Arg : 'a * 'a Term.t -> ('a, final) arg

let infos k ?docs ?docv ?doc ?env aka =
  let env = match env with
    | None -> None
    | Some e -> Some (Arg.env_var ?docs ?doc e) in
  let infos = Arg.info ?docs ?docv ?doc ?env aka in
  k infos

let flag ?docs ?docv ?doc ?env aka : (bool, spec) arg =
  let k info = Spec (false, Arg.flag info) in
  infos k ?docs ?docv ?doc ?env aka

let opt ?docs ?docv ?doc ?env ?vopt ~conv ~default aka =
  let k info = Spec (default, Arg.opt ?vopt conv default info) in
  infos k ?docs ?docv ?doc ?env aka

let opt_all ?docs ?docv ?doc ?env ?vopt ~conv ~default aka =
  let k info = Spec (default, Arg.opt_all ?vopt conv default info) in
  infos k ?docs ?docv ?doc ?env aka

let pos ?docs ?docv ?doc ?env ?rev ~conv ~default ~index aka =
  let k info = Spec (default, Arg.pos ?rev index conv default info) in
  infos k ?docs ?docv ?doc ?env aka

let pos_all ?docs ?docv ?doc ?env ~conv ~default aka =
  let k info = Spec (default, Arg.pos_all conv default info) in
  infos k ?docs ?docv ?doc ?env aka

let value : ('a, spec) arg -> ('a, final) arg =
  function Spec (d, a) -> Arg (d, Arg.value a)

let required : ('a option, spec) arg -> ('a, final) arg =
  function
  | Spec (Some d, a) -> Arg (d, Arg.required a)
  | _ -> invalid_arg "required"

let non_empty : ('a list, spec) arg -> ('a list, final) arg =
  function Spec (d, a) -> Arg (d, Arg.non_empty a)

let last : ('a list, spec) arg -> ('a, final) arg =
  function Spec (d, a) -> Arg (List.nth d (List.length d - 1), Arg.last a)

type env = Cmdliner.Term.env_info

let env = Term.env_info

type cfg = unit Term.t ref

let create () = ref (Term.const ())

let register : cfg -> ('b, final) arg -> unit -> 'b = fun cfg (Arg (d, t)) ->
  let cell = ref d in
  let set v () = cell := v in
  cfg := Term.(const set $ t $ !cfg);
  fun () -> !cell

type 'a command = {
  cfg : cfg; [@default (create ())]
  cmd : (unit -> 'a); [@main]
  man_xrefs : Manpage.xref list; [@default []]
  man : Manpage.block list; [@default []]
  envs : Term.env_info list; [@default []]
  doc : string; [@default ""]
  version : string option; [@default None]
  name : string; [@default (Filename.basename Sys.executable_name)]
}[@@deriving make]

let command = make_command


let term : 'a command -> ('a Term.t * Term.info) = fun cmd ->
  let info = Term.info
      ~man_xrefs:cmd.man_xrefs
      ~man:cmd.man
      ~envs:cmd.envs
      ~doc:cmd.doc
      ?version:cmd.version
      cmd.name in
  Term.(const cmd.cmd $ !(cmd.cfg)), info

let run : 'a command -> unit = fun cmd ->
  Term.exit @@ Term.eval (term cmd)


let bool = Arg.bool
let char = Arg.char
let int = Arg.int
let nativeint = Arg.nativeint
let int32 = Arg.int32
let int64 = Arg.int64
let float = Arg.float
let string = Arg.string
let enum = Arg.enum
let file = Arg.file
let dir = Arg.dir
let non_dir_file = Arg.non_dir_file
let list = Arg.list
let array = Arg.array
let pair = Arg.pair
let t2 = Arg.t2
let t3 = Arg.t3
let t4 = Arg.t4
