.PHONY: test-e2e clean lint

${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

# snapshot
# nf-test snapshot tests
test-e2e: test-fastq-snapshot
	echo "Execute entrypoint of test-fastq-snapshot"

# nf-test snapshot tests
test-fastq-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
			--verbose \
			--profile docker,test_fastq

# Update nf-test snapshots
test-fastq-update-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
			tests/default.nf.test \
			--verbose \
			--update-snapshot \
			--profile docker,test_fastq

# FASTQ input test - full pipeline with alignment
test-fastq: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		-profile docker,test_fastq \
		-resume
# Lint
lint: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow lint $(shell find . -name "*.nf" \
		-not -path "./.pixi/*" \
		-not -path "./.nextflow/*" \
		-not -path "./work/*" \
		-not -path "./results/*") -format

# Clean
clean:
	rm -rf work results .nextflow* *.log
