#!/bin/bash

source logger.lib

JSON='{"employees":[{"firstName":"John", "lastName":"Doe"},{"firstName":"Anna", "lastName":"Smith"},{"firstName":"Peter", "lastName":"Jones"}]}'

validate_json "${JSON}"
