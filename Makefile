validate_schemas:
	npx ajv validate --spec draft2020 -s schemas/course-definition.json -d ../course-definition.yml
	ls ../solutions/*/*/definition.yml | xargs -P8 -n 1 npx ajv validate --spec draft2020 -s schemas/course-stage-solution-definition.json -d
