(* mini molecule module *)

(* Copyright (C) 2018, Francois Berenger

   Yamanishi laboratory,
   Department of Bioscience and Bioinformatics,
   Faculty of Computer Science and Systems Engineering,
   Kyushu Institute of Technology,
   680-4 Kawazu, Iizuka, Fukuoka, 820-8502, Japan. *)

module A = BatArray
module IntSet = BatSet.Int
module L = MyList
module StringMap = BatMap.String

type t = { name: string;
           graph: Node.t array }

let get_name m = m.name

let get_graph m = m.graph

let nb_atoms m =
  A.length m.graph

let create name graph =
  { name; graph }

let to_string (m: t): string =
  let buff = Buffer.create 80 in
  Buffer.add_string buff m.name;
  Buffer.add_char buff '\n';
  A.iter (fun n ->
      Buffer.add_string buff (Node.to_string n);
      Buffer.add_char buff '\n';
    ) m.graph;
  Buffer.contents buff

let get_typ (m: t) (i: int) =
  Node.get_typ m.graph.(i)

let get_succs (m: t) (i: int) =
  Node.get_succs m.graph.(i)

(* canonicalized count of atom types *)
let count_typs (typs: Sybyl.t list): (Sybyl.t * int) list =
  let typ2count = Hashtbl.create 11 in
  L.iter (fun typ ->
      let prev_count = BatHashtbl.find_default typ2count typ 0 in
      BatHashtbl.replace typ2count typ (prev_count + 1)
    ) typs;
  (* canonicalize the atom env by sorting it *)
  List.sort compare (BatHashtbl.to_list typ2count)

let mop2d_encode (max_blength: int) (mol: t): Mop2d_env.t list =
  (* extract the atom env. of given atom, up to maximum bond length *)
  let encode_atom (n_i: int): Mop2d_env.t =
    let center_atom = mol.graph.(n_i) in
    let center_atom_typ = Node.get_typ center_atom in
    let rec loop acc curr_blength to_visit visited =
      if to_visit = IntSet.empty || curr_blength = max_blength then
        (center_atom_typ, L.rev acc)
      else
        let visited' = IntSet.union to_visit visited in
        let to_visit' =
          let res =
            IntSet.fold (fun i acc ->
                let succs = get_succs mol i in
                IntSet.union succs acc
              ) to_visit IntSet.empty
          in
          IntSet.diff res visited' in
        let curr_blength' = curr_blength + 1 in
        let succs_typs =
          IntSet.fold (fun i acc ->
              get_typ mol i :: acc
            ) to_visit' [] in
        let counted_succs_typs = count_typs succs_typs in
        let acc' =
          if counted_succs_typs = [] then
            acc
          else
            counted_succs_typs :: acc in
        loop acc' curr_blength' to_visit' visited' in
    loop [] 0 (IntSet.singleton n_i) IntSet.empty
  in
  let unsorted =
    A.fold_lefti (fun acc i _ ->
        encode_atom i :: acc
      ) [] mol.graph in
  (* canonicalize the encoding of the molecule by sorting its atom envs *)
  List.sort compare unsorted
