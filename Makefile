.PHONY: test-e2e test-rastair test-bsbolt clean lint

${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

# snapshot
# nf-test snapshot tests
test-e2e: test-rastair-snapshot
	echo "Execute entrypoint of test-fastq-snapshot"

# Rastair
test-rastair-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		tests/rastair.nf.test \
		--verbose \
		--profile docker,rastair

test-rastair-update-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		tests/rastair.nf.test \
		--verbose \
		--update-snapshot \
		--profile docker,rastair

test-rastair: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		-profile docker,rastair \
		-resume


# BSbolt
test-bsbolt: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		-profile docker,bsbolt \
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
