#!/bin/bash

# Configuration
TEST_FILE="integration_test/sms_response_test.dart"
DEVICE_ID="emulator-5554"
LOG_FILE="test_output.log"

# Get absolute path for log file
ROOT_DIR=$(pwd)
ABS_LOG_FILE="$ROOT_DIR/$LOG_FILE"

echo "🚀 Starting SMS Response Integration Test on $DEVICE_ID..."
echo "📝 Logging to $ABS_LOG_FILE"
rm -f "$ABS_LOG_FILE"
touch "$ABS_LOG_FILE"

# Start flutter test in the background
cd app && flutter test $TEST_FILE -d $DEVICE_ID > "$ABS_LOG_FILE" 2>&1 &
TEST_PID=$!

# Function to cleanup background process on exit
cleanup() {
  echo "🧹 Cleaning up..."
  if kill -0 $TEST_PID 2>/dev/null; then
    kill $TEST_PID
  fi
}
trap cleanup EXIT

echo "⏳ Waiting for test to signal ready for response (this may take a few minutes to build)..."

# Monitor the log file for the specific tag
MAX_RETRIES=600 # 20 minutes roughly
COUNT=0
READY=false

while [ $COUNT -lt $MAX_RETRIES ]; do
  if grep -q "TEST_READY_FOR_RESPONSE" "$ABS_LOG_FILE"; then
    READY=true
    break
  fi
  
  if ! kill -0 $TEST_PID 2>/dev/null; then
    # Test might have finished or crashed
    if grep -q "TEST_READY_FOR_RESPONSE" "$ABS_LOG_FILE"; then
        READY=true
        break
    fi
    echo "❌ Test process exited early."
    tail -n 20 "$ABS_LOG_FILE"
    exit 1
  fi
  
  # Print a dot every 10 seconds to show progress
  if [ $((COUNT % 5)) -eq 0 ]; then
    echo -n "."
  fi
  
  sleep 2
  COUNT=$((COUNT + 1))
done

echo "" # Newline after dots

if [ "$READY" = true ]; then
  # Extract numbers - handle potential trailing \r from android logs
  ADVISOR_PHONE=$(grep "TEST_READY_FOR_RESPONSE" "$ABS_LOG_FILE" | sed -n 's/.*advisorPhone=\([^ ]*\).*/\1/p' | head -n 1 | tr -d '\r' | xargs)
  CLIENT_PHONE=$(grep "TEST_READY_FOR_RESPONSE" "$ABS_LOG_FILE" | sed -n 's/.*clientPhone=\([^ ]*\).*/\1/p' | head -n 1 | tr -d '\r' | xargs)
  
  echo "📱 Signal received! Simulating response..."
  echo "   Advisor: $ADVISOR_PHONE"
  echo "   Client:  $CLIENT_PHONE"
  
  # Run the simulation script from the root
  cd "$ROOT_DIR"
  python3 scripts/simulate_sms_response.py --to "$ADVISOR_PHONE" --from "$CLIENT_PHONE" --msg "Simulation successful! I want to upgrade my policy."
  
  echo "✅ Simulation triggered. Waiting for test to complete..."
else
  echo "❌ Timed out waiting for test signals."
  tail -n 50 "$ABS_LOG_FILE"
  exit 1
fi

# Wait for the test process to finish
wait $TEST_PID
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "🎉 Test Passed!"
else
  echo "❌ Test Failed with code $TEST_EXIT_CODE"
  # tail -n 50 "$ABS_LOG_FILE"
fi

exit $TEST_EXIT_CODE
