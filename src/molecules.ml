(* Copyright (C) 2018, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module IntMap = MyIntMap
module L = MyList
module Log = Dolog.Log
module FpMol = Molenc.FpMol

let read_one count input =
  FpMol.parse_one count (input_line input)

let from_file fn =
  let count = ref 0 in
  let mols =
    Utls.with_in_file fn (fun input ->
        let res, exn =
          L.unfold_exc (fun () ->
              let res = read_one !count input in
              incr count;
              res
            ) in
        if exn <> End_of_file then raise exn;
        res
      ) in
  Log.info "read %d from %s" !count fn;
  mols
