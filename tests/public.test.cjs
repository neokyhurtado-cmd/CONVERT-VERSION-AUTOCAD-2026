"use strict";
const test=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const cp=require("node:child_process");
const root=path.resolve(__dirname,"..");
function read(p){return fs.readFileSync(path.join(root,p),"utf8");}
const publicEvidence=JSON.parse(read("docs/qa-results-public.json"));
const targets={"2007":"AC1021","2018":"AC1032","2010":"AC1024","2004":"AC1018","2000":"AC1015","R14":"AC1014","2007_TO_2018":"AC1032"};
test("7 conversion outcomes in sanitized public evidence",()=>{
 assert.equal(publicEvidence.converters_executed,7);
 assert.equal(publicEvidence.conversions_passed,7);
 assert.equal(publicEvidence.outcomes.length,7);
 assert.equal(publicEvidence.sample_count,1);
 assert.equal(publicEvidence.baseline_entity_count,3043);
 for(const row of publicEvidence.outcomes){
   assert.ok(row.opened_in_AutoCAD_2027);
   assert.equal(row.entities_original,3043);
   assert.equal(row.entities_output,3043);
   assert.ok(row.entity_type_counts_unchanged);
   assert.ok(row.layer_counts_unchanged);
   assert.ok(row.layout_entity_counts_unchanged);
   assert.ok(row.anonymous_block_identifiers_changed);
   const key=row.transition.includes("2007 → DWG 2018")?"2007_TO_2018":row.transition.split("DWG ").pop();
   assert.equal(row.dwg_header_to,targets[key],row.transition);
 }
});
test("8 CAD inventory inspections and 10 browser checks are expressly scoped",()=>{
 assert.equal(publicEvidence.autoCAD_openings_checked,8);
 assert.equal(publicEvidence.cad_inventories_passed,8);
 assert.equal(publicEvidence.real_DWG_browser_tests_passed,10);
 assert.match(publicEvidence.caution,/ONE real drawing/);
 assert.match(publicEvidence.private_data_policy,/kept private/);
});
test("release contains real converter, launcher, LICENSE and unbundled CAD",()=>{
 const script=read("Convertir-DWG.ps1");
 const launcher=read("INICIAR-CONVERSOR.cmd");
 assert.match(script,/Find-CoreConsole/);
 assert.match(script,/Read-DwgCode/);
 assert.match(script,/Run-Core/);
 assert.match(script,/Get-FileHash/);
 assert.match(script,/SAVEAS/);
 assert.match(script,/reopen\.pass/);
 assert.match(launcher,/Convertir-DWG\.ps1/);
 assert.match(read("LICENSE"),/^MIT License/);
 assert.match(read("NOTICE.md"),/AutoCAD Core Console/);
});
test("web app source syntax and local-only six byte read",()=>{
 const scriptPath=path.join(root,"web","dwg-versiones.js");
 const syntax=cp.spawnSync(process.execPath,["--check",scriptPath],{encoding:"utf8"});
 assert.equal(syntax.status,0,syntax.stderr);
 const script=read("web/dwg-versiones.js");
 assert.match(script,/file\.slice\(0,6\)/);
 assert.doesNotMatch(script,/\b(?:fetch|XMLHttpRequest)\s*\(/);
});
test("no customer DWG files tracked in open source tree",()=>{
 const forbiddenExtensions=/\.(?:dwg|dxf|dwt|bak|db|sqlite|pfx|pem|p12)$/i;
 const forbiddenNames=new RegExp("(?:"+"SAN"+"[\\s_-]?"+"FELIPE"+"|pmt"+"-corpus"+"|qa-real"+"-matrix"+"|private"+"\\\\qa"+")","i");
 function visit(folder){
  for(const e of fs.readdirSync(folder,{withFileTypes:true})){
   if(e.name===".git"||e.name==="node_modules")continue;
   const rel=path.relative(root,path.join(folder,e.name)).replace(/\\/g,"/");
   assert.ok(!forbiddenExtensions.test(rel),"Forbidden CAD/private artifact: "+rel);
   if(e.isDirectory())visit(path.join(folder,e.name));
   else if(/\.(?:md|json|js|cjs|ps1|html|css|txt|cmd)$/i.test(e.name)){
     const content=fs.readFileSync(path.join(folder,e.name),"utf8");
     assert.ok(!forbiddenNames.test(content),"Private file/source name in "+rel);
     assert.ok(!/C:\\Users\\david|X:\\TraficLabPro/i.test(content),"Private absolute path in "+rel);
   }
  }
 }
 visit(root);
});
