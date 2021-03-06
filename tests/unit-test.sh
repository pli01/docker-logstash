#!/bin/bash
set -x

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
VERSION=${2:-latest}
namespace=logstash
logstash=logstash
export VERSION

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose -p ${namespace} config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose -p ${namespace} config"
else
  echo "[FAILED] docker-compose -p ${namespace} config"
  ret=1
fi
echo "Check logstash installed"
docker-compose -p ${namespace} run --name "test-logstash" --rm $logstash ls -l /opt/
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] logstash installed"
else
  echo "[FAILED] logstash installed"
  ret=1
fi

# test a small nginx config
echo "Check logstash running"

# setup test
echo "# setup env test:"
test_compose=docker-compose.yml
logstash=logstash
test_config=logstash-test.sh
docker-compose -p ${namespace} -f $test_compose up -d --no-build $logstash
docker-compose -p ${namespace} -f $test_compose ps $logstash
container=$(docker-compose -p ${namespace}  -f $test_compose ps -q $logstash)
echo docker cp $test_config ${container}:/opt
docker cp $test_config ${container}:/opt

# run test
echo "# run test:"
docker-compose -p ${namespace}  -f $test_compose exec -T $logstash /bin/bash -c "/opt/$test_config"
test_result=$?

# teardown
echo "# teardown:"
docker-compose -p ${namespace}  -f $test_compose stop
docker-compose -p ${namespace}  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] logstash url check [$test_config]"
else
  echo "[FAILED] logstash url check [$test_config]"
  ret=1
fi

exit $ret
