run_r() {
	if command -v sbatch > /dev/null && [ -f run.sbatch ]; then
		command1="module load R";
		command2="Rscript --vanilla $*";
		jobname=$(basename "${1%.*}");
		print_info R "$@";
		sbatch -W --export=command1="$command1",command2="$command2" --job-name="$jobname" run.sbatch;
	else
		print_info R "$@";
		Rscript --vanilla "$@";
	fi;
}

print_info() {
	software=$1;
	shift;
	if [ "$#" = 1 ]; then
		echo "Running $1 via $software, waiting...";
	else
		echo "Running $1 via $software with args = ${*:2}, waiting...";
	fi;
}
