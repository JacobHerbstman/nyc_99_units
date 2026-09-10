# Shared code

Reusable data and estimation helpers, language execution settings, standard data reports, and Make directory rules live here. Task scripts own the transformations; Makefiles name their actual inputs and outputs.

Upstream checks are grouped by owning task. Each check runs that task once, including its standard reports and the named files needed by the consumer. The concrete upstream-file rules use an explicit empty recipe (`;`). GNU Make 3.81 needs it to re-read file timestamps after the recursive check; without it, a changed upstream file can leave the consumer stale for one invocation. This was checked with a disposable two-task build, including changed inputs and missing outputs.

A coherent producer writes its primary file before its companion files. A missing companion reruns that concrete producer through the task's `all` target using `$(RECOVER) -W producer.R all`. `RECOVER` expands to Make, but the indirect reference makes `make -n` print the recovery command without executing another dry run. Ordinary upstream checks retain direct `$(MAKE)` calls. This also updates its reports and downstream exhibits inside the same recursive build; rebuilding only the primary file can leave Make's cached primary timestamp stale for later rules in the outer invocation. Primary outputs precede their companions in `all`. Tasks are serial internally (`.NOTPARALLEL`) so requesting several missing companions under `make -j` cannot start overlapping writers. Separate release specifications still have separate targets.

The atomic writers publish a completed temporary file by renaming it. Make owns incrementality; helpers do not decide whether a result is stale by comparing its bytes or searching for cached releases.

The legacy date parser rejected dates more than one year ahead of the build date. Its upper validity bound is now fixed at September 9, 2027, preserving the rule at this overhaul while removing dependence on the computer clock. Future source refreshes should review that explicit bound.

For analyses with fixed output filenames, specification changes belong in the tracked task Makefile. Command-line overrides of those settings are rejected: otherwise Make cannot distinguish an old result from a different specification when the filename is unchanged. Specifications encoded in filenames, such as parcel releases and plot measures, remain ordinary separate targets.

When combining producers in one task, list an upstream primary output before its companion outputs and the downstream producers in `all`. This avoids GNU Make 3.81 caching a companion timestamp before its producer updates it. Recovery was checked with fresh builds, missing companions under `-j4`, changed inputs, and unchanged second builds.
