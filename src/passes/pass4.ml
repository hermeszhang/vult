(*
The MIT License (MIT)

Copyright (c) 2014 Leonardo Laguna Ruiz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*)

open PassCommon
open VEnv
open TypesVult
open Common

module ReplaceFunctionNames = struct

   let exp : ('a Env.t,exp) Mapper.mapper_func =
      Mapper.make "ReplaceFunctionNames.exp" @@ fun state exp ->
      match exp with
      | PCall(name,fname,args,attr) ->
         let Path(path),_,t = Env.lookupRaise Scope.Function state fname attr.loc in
         let final_name =
            match !(t.Scope.ext_fn) with
            | Some(n) -> [n]
            | None -> path
         in
         state, PCall(name,final_name,args,attr)
      | _ -> state,exp

   let stmt : (PassData.t Env.t,stmt) Mapper.mapper_func =
      Mapper.make "ReplaceFunctionNames.stmt" @@ fun state stmt ->
      match stmt with
      | StmtFun([_],args,body,rettype,attr) ->
         let Path(path) = Env.currentScope state in
         state, StmtFun(path,args,body,rettype,attr)
      | _ ->
         state, stmt

   let vtype_c : (PassData.t Env.t,VType.vtype) Mapper.mapper_func =
      Mapper.make "ReplaceFunctionNames.vtype_c" @@ fun state typ ->
      match typ with
      | VType.TId(id,optloc) ->
         let loc =
            match optloc with
            | Some(loc) -> loc
            | None -> Loc.default
         in
         let Path(type_path),_,_ = Env.lookupRaise Scope.Type state id loc in
         state, VType.TId(type_path,optloc)
      | _ -> state, typ

   let mapper = Mapper.{ default_mapper with exp; stmt; vtype_c }

end

module ReturnReferences = struct

   let unitAttr attr = { attr with typ = Some(VType.Constants.unit_type)}

   let stmt : (PassData.t Env.t,stmt) Mapper.mapper_func =
      Mapper.make "ReturnReferences.stmt" @@ fun state stmt ->
      let data = Env.get state in
      if not data.PassData.args.ccode then
         state, stmt
      else
         match stmt with
         | StmtFun(name,args,body,Some(rettype),attr) when not (VType.isSimpleType rettype) ->
            let output = TypedId(["_output_"],rettype,OutputArg,emptyAttr) in
            let stmt' = StmtFun(name,args@[output],body,Some(VType.Constants.unit_type),attr) in
            state, stmt'
         | _ -> state, stmt

   let stmt_x : ('a Env.t,stmt) Mapper.expand_func =
      Mapper.makeExpander "ReturnReferences.stmt_x" @@ fun state stmt ->
      let data = Env.get state in
      if not data.PassData.args.ccode then
         state, [stmt]
      else
         match stmt with
         (* regular case a = foo() *)
         | StmtBind(LId(lhs,Some(typ),lattr),PCall(inst,name,args,attr),battr) when not (VType.isSimpleType typ) ->
            let arg = PId(lhs,lattr) in
            let fixed_attr = unitAttr attr in
            state, [StmtBind(LWild(fixed_attr),PCall(inst,name,args@[arg],attr),battr)]
         (* special case _ = foo() when the return is no simple value *)
         | StmtBind(LWild(wattr),PCall(inst,name,args,attr),battr) when not (VType.isSimpleOpType wattr.typ) ->
            let i,state' = Env.tick state in
            let tmp_name = "_unused_" ^ (string_of_int i) in
            let arg = PId([tmp_name], wattr) in
            let fixed_attr = unitAttr attr in
            state', [StmtVal(LId([tmp_name],wattr.typ,wattr),None,battr);StmtBind(LWild(fixed_attr),PCall(inst,name,args@[arg],attr),battr)]
         (* special case _ = a when a is not simple value *)
         | StmtBind(LWild(wattr),e,battr) when not (VType.isSimpleOpType wattr.typ) ->
            let i,state' = Env.tick state in
            let tmp_name = "_unused_" ^ (string_of_int i) in
            state', [StmtVal(LId([tmp_name],wattr.typ,wattr),None,battr);StmtBind(LId([tmp_name],wattr.typ,wattr),e,battr)]
         | StmtBind(_,PCall(_,_,_,_),_) ->
            state, [stmt]
         | StmtVal(LId(lhs,Some(typ),lattr),Some(PCall(inst,name,args,attr)),battr) when not (VType.isSimpleType typ) ->
            let arg = PId(lhs,lattr) in
            let fixed_attr = unitAttr attr in
            state, [StmtVal(LId(lhs,Some(typ),lattr),None,battr);StmtBind(LWild(fixed_attr),PCall(inst,name,args@[arg],attr),battr)]
         | StmtVal(_,Some(PCall(_,_,_,_)),_) ->
            state, [stmt]
         | StmtReturn(e,attr) ->
            let eattr = GetAttr.fromExp e in
            if not (VType.isSimpleOpType eattr.typ) then
               let stmt' = StmtBind(LId(["_output_"],eattr.typ,eattr),e,attr) in
               reapply state, [stmt';StmtReturn(PUnit(unitAttr eattr),attr)]
            else
               state, [stmt]

         | _ -> state, [stmt]


   let mapper = Mapper.{ default_mapper with stmt; stmt_x }


end

module DummySimplifications = struct

   let stmt : (PassData.t Env.t,stmt) Mapper.mapper_func =
      Mapper.make "DummySimplifications.stmt" @@ fun state stmt ->
      match stmt with
      | StmtVal(LWild(wattr),Some(rhs),attr) ->
         state, StmtBind(LWild(wattr),rhs,attr)
      | _ -> state, stmt

   let stmt_x : ('a Env.t,stmt) Mapper.expand_func =
      Mapper.makeExpander "DummySimplifications.stmt_x" @@ fun state stmt ->
      match stmt with
      | StmtVal(LWild(_),None,_) ->
         state, []
      | _ -> state, [stmt]

   let mapper = Mapper.{ default_mapper with stmt; stmt_x }

end

let run =
   ReplaceFunctionNames.mapper
   |> Mapper.seq ReturnReferences.mapper
   |> Mapper.seq DummySimplifications.mapper