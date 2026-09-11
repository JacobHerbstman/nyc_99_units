"""Render the production task graph from concrete Makefile input prerequisites.

Run through the root Makefile from the repository root.
"""
from pathlib import Path
import re
import subprocess
import textwrap

edges = set()
tasks = set()
for makefile in sorted(Path('tasks').glob('*/code/Makefile')):
    task = makefile.parents[1].name
    if task in {'shared', 'setup_environment', 'source_registry'}:
        continue
    tasks.add(task)
    text = makefile.read_text().replace('\\\n', ' ')
    for prerequisite in re.findall(r'^\.\./input/[^:]+:\s+(\S+)', text, re.M):
        # Resolve through the declared path, not through an existing input link.
        parts = Path(prerequisite).parts
        if 'output' in parts or 'code' in parts:
            folder = 'output' if 'output' in parts else 'code'
            owner = parts[parts.index(folder) - 1]
            if owner != task and owner not in {".", ".."}:
                edges.add((owner, task))
                tasks.add(owner)

root_rules = Path("Makefile").read_text().replace("\\\n", " ")
root_edges = set()
for task, prerequisites in re.findall(r"^([a-z][a-z0-9_]+):([^\n]*)", root_rules, re.M):
    if task in tasks:
        root_edges.update((source, task) for source in prerequisites.split() if source in tasks)
if root_edges != edges:
    raise ValueError(f"Root/task dependency mismatch: {sorted(root_edges ^ edges)}")

lines = ['digraph tasks {', 'rankdir=TB;',
         'graph [bgcolor="white", pad=0.2, nodesep=0.15, ranksep=0.35];',
         'node [shape=box, style="rounded,filled", fillcolor="#edf3f8", color="#8196a8", fontname="Helvetica", fontsize=10];',
         'edge [color="#8196a8", arrowsize=0.5];']
for task in sorted(tasks):
    label = textwrap.fill(task.replace('_', ' '), width=24).replace('\n', '\\n')
    lines.append(f'"{task}" [label="{label}"];')
for source, target in sorted(edges):
    lines.append(f'"{source}" -> "{target}";')
lines.append('}')
reduced = subprocess.run(['tred'], input='\n'.join(lines), text=True,
                         capture_output=True, check=True).stdout
subprocess.run(['dot', '-Tsvg', '-o', 'task_graph.svg'],
               input=reduced, text=True, check=True)
