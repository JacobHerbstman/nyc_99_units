include ../../../shared/code/shell_functions.make

all: ../output/4121_third_rawp_2025-10-01.pdf

include ../../../shared/code/generic.make

# 4121 Third Avenue remedial action work plan (NYC OER), read by
# audit_estimation_parent_links for its site-plan figure.
../output/4121_third_rawp_2025-10-01.pdf: | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/a42e12f9-ce9f-f011-8274-005056b05749/download' --output ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@
