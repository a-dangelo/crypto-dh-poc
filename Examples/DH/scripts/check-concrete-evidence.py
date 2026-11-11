#!/usr/bin/env python3
"""Validate concrete proof evidence and produce a source-hashed report."""
import hashlib
import os
import json
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
evidence = root / 'concrete/evidence'
allowed = {'propext', 'Classical.choice', 'Quot.sound', 'RustAx.core', 'RustAx.subtle'}
required = {'DhConcrete.nativeAdvantage_eq', 'DhConcrete.nativeAdvantage_le',
            'DhConcrete.uniformWide_decode', 'DhConcrete.wideAdvantage_eq', 'DhConcrete.wideAdvantage_le',
            'DhConcrete.uniformWide_scalar_measureETVDist_le', 'DhPoc.sampledDDHAdvantage_le_standard',
            'DhConcrete.four_wideSamplingError_lt', 'DhConcrete.wideAdvantage_le_of_standardDDH'}
audit = (evidence/'axioms.log').read_text()
entries = re.findall(r"'([^']+)' depends on axioms: \[([^]]*)\]", audit, re.S)
if not required.issubset(name for name, _ in entries):
    raise SystemExit('Missing final endpoint in axiom audit')
for name, axioms in entries:
    if {x.strip() for x in axioms.split(',')} - allowed:
        raise SystemExit(f'Unexpected axiom closure: {name}')
if 'Build completed successfully' not in (evidence/'final-build.log').read_text():
    raise SystemExit('Concrete default build did not complete successfully')
if '128 deterministic sessions agree' not in (evidence/'smoke.log').read_text():
    raise SystemExit('Native smoke check is missing')
if 'exit_code=0' not in (evidence/'extract.log').read_text():
    raise SystemExit('Successful full extraction is missing')
link = json.loads((evidence/'linkage-comparison.json').read_text())
for filename in ['Types.lean', 'Funs.lean']:
    if link[filename]['missing'] or link[filename]['changed']:
        raise SystemExit('Backend linkage does not match')

def record(path):
    data=path.read_bytes()
    return {'sha256':hashlib.sha256(data).hexdigest(), 'lines':len(data.splitlines())}
paths = sorted((root/'concrete/Concrete').glob('*.lean'))
paths += sorted((root/'lean/DhPoc').rglob('*.lean'))
paths += [root/'concrete/rust/poc_dh.rs']
files = {str(p.relative_to(root)):record(p) for p in paths}
for p in paths:
    if p.suffix=='.lean':
        code=re.sub(r'/\-.*?\-/|--[^\n]*','',p.read_text(),flags=re.S)
        if re.search(r'\b(sorry|admit|axiom)\b',code):
            raise SystemExit(f'Admission or custom axiom in {p}')
modules={}
for prefix, folder in [('Concrete',root/'concrete/Concrete'),('DhPoc',root/'lean/DhPoc')]:
    for p in folder.rglob('*.lean'):
        modules[prefix+'.'+'.'.join(p.relative_to(folder).with_suffix('').parts)] = p
seen=set()
def visit(name):
    if name not in modules or name in seen: return
    seen.add(name)
    for dep in re.findall(r'^(?:public )?import ([A-Za-z0-9_.]+)',modules[name].read_text(),re.M): visit(dep)
visit('Concrete.Wide')
wide_path=set(seen)
visit('Concrete.Standard')
concrete=[p for p in paths if '/concrete/Concrete/' in str(p)]
generic=[p for p in paths if '/lean/DhPoc/' in str(p)]
generated=[root/'concrete/Concrete/GeneratedAdapter.lean',root/'lean/DhPoc/Generated/DhCore.lean']
count=lambda ps:sum(record(p)['lines'] for p in ps)
pins={
 'lean':'v4.35.0','aeneas':'de16f3cf877976e966906dc890f63dcb418884fa',
 'aeneas_release':'nightly-2026.10.30-de16f3c',
 'aeneas_bundle_sha256':'0963dc77cab890de16b213b903091721961afca6303b9b0ea05ff8d76013f624',
 'charon':'373d84044d80f6eb44285c2c349bae1453f5b6ca',
 'rust_extraction':'nightly-2026-09-17',
 'dalek_proof':'95b5831c63ff1c5f6287bd3a77569412a9afdbfb',
 'elliptic_curve':'4015c7cfab714640e77500bdbde6e64face3fbaa',
 'vcvio':'88efe9715a9fa9e7d89635c38cf70259836766c2',
 'mathlib':'56a005855ea17e0b0958f73ec801ae140b0a1679'}
for folder,key in [('vendor/dalek-proof','dalek_proof'),('concrete/vendor/EllipticCurve','elliptic_curve'),('vendor/VCVio','vcvio')]:
    head=subprocess.check_output(['git','-C',str(root/folder),'rev-parse','HEAD'],text=True).strip()
    if head!=pins[key]: raise SystemExit(f'Wrong {key} revision')
    subprocess.run(['git','-C',str(root/folder),'diff','--quiet','HEAD'],check=True)
extraction=json.loads((evidence/'extraction-inputs.json').read_text())
for rel, expected in extraction['inputs'].items():
    if record(root/rel)['sha256']!=expected: raise SystemExit('Stale extraction input: '+rel)
for rel, expected in extraction['patches'].items():
    if record(root/'vendor/dalek-proof'/rel)['sha256']!=expected: raise SystemExit('Stale extraction patch: '+rel)
patches={str(p.relative_to(root/'vendor/dalek-proof')):record(p) for p in sorted((root/'vendor/dalek-proof/curve25519-dalek/translation-patches').glob('*.patch'))}
report={
 'status':'checked_end_to_end_standard_DDH_reduction', 'pins':pins,
 'latest_check_mode':os.environ.get('POC_CHECK_MODE','evidence-only'),
 'extraction_input_manifest':'extraction-inputs.json',
 'verified_program':'Rust DH wrapper plus patched pinned BAIF dalek 5.0.0, serial x86_64 without precomputed tables',
 'endpoint':'DhConcrete.nativeAdvantage_eq', 'wide_endpoint':'DhConcrete.wideAdvantage_le',
 'standard_endpoint':'DhConcrete.wideAdvantage_le_of_standardDDH',
 'standard_bound':'epsilon + 2^(-260)',
 'sampler_bound':'TV(decoded uniformWide, uniform ZMod L) <= r / 2^512, r = 2^512 mod L',
 'hybrid_loss':'Two independent scalar replacements in each branch: 4*r/2^512 < 2^(-260)',
 'advantage_normalization':'Absolute difference of true-event probabilities (VCVio boolDist)',
 'actual_generated_session':'Curve25519Dalek.poc_dh.session',
 'configuration_premise':'Aeneas.Std.target = "x86_64-no-tables"',
 'hardness_premise':'Standard uniform-scalar DDH advantage for the explicit encoding reduction is at most epsilon',
 'alternative_hardness_premise':'The original exact wide endpoint retains its separate sampled-DDH premise',
 'wide_sampler':'Two independent uniform integers below 256^64, encoded little-endian and reduced modulo L',
 'primitive_contract_hypotheses':[], 'axioms':sorted(allowed),
 'audited_declarations':{name:[x.strip() for x in axioms.split(',')] for name,axioms in entries},
 'counts':{'generic_modules':count(generic),'concrete_modules':count(concrete),
           'all_local_lean_modules':count(concrete+generic),'generated_lean':count(generated),
           'handwritten_lean':count(concrete+generic)-count(generated),
           'wide_endpoint_import_path':count([modules[n] for n in wide_path]),
           'standard_endpoint_import_path':count([modules[n] for n in seen]),
           'largest_file':max(record(p)['lines'] for p in concrete+generic)},
 'files':files,'translation_patches':patches,
 'checks':['full Rust extraction exits 0','all upstream generated backend declarations match',
           'default concrete Lean build includes Sampler, Wide, and Standard',
           'proved modulo-sampling TV bound, standard-DDH hybrids, and exact numeric loss',
           'fresh full axiom audit',
           '128 native deterministic differential sessions and malformed-input rejection'],
 'not_claimed':['unpatched-source equivalence','sharp exact total-variation formula',
                'OS RNG verification','compiler or machine-code verification','authentication',
                'active or multisession security','side-channel security','KDF or uniform byte-string keys']}
(evidence/'concrete-proof-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':report['status'],'counts':report['counts'],'audited':len(entries)},indent=2))
