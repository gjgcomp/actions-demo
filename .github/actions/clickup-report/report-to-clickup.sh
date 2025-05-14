#!/usr/bin/env bash
set -e

echo "💬 Reporting test result to ClickUp task $CLICKUP_TASK_ID..."

if [ "$TEST_FAILED" == "true" ]; then
  OPTION_NAME="False"
  STATUS="issues found"
else
  OPTION_NAME="True"
  STATUS="in staging"
fi

# Fetch current task details
echo "📥 Fetching task metadata..."
RESPONSE=$(curl --silent --location --request GET "https://api.clickup.com/api/v2/task/$CLICKUP_TASK_ID" \
  --header "Authorization: $CLICKUP_TOKEN" \
  --header "Content-Type: application/json")

CUSTOM_FIELD_ID=$(echo "$RESPONSE" | jq -r '.custom_fields[] | select(.name=="☑️ Task Passed") | .id')
OPTION_ID=$(echo "$RESPONSE" | jq -r ".custom_fields[] | select(.name==\"☑️ Task Passed\") | .type_config.options[] | select(.name==\"$OPTION_NAME\") | .id")

echo "📤 Updating task status to '$STATUS'..."
curl --silent --location --request PUT "https://api.clickup.com/api/v2/task/$CLICKUP_TASK_ID" \
  --header "Authorization: $CLICKUP_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$(jq -n --arg status "$STATUS" '{status: $status}')"

echo "📤 Updating custom field with result '$OPTION_NAME'..."
curl --silent --location --request POST "https://api.clickup.com/api/v2/task/$CLICKUP_TASK_ID/field/$CUSTOM_FIELD_ID" \
  --header "Authorization: $CLICKUP_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$(jq -n --arg option "$OPTION_ID" '{value: $option}')"

if [ -n "$ATTACHMENT" ]; then
  echo "📎 Uploading attachment: $ATTACHMENT"
  curl --silent --location --request POST "https://api.clickup.com/api/v2/task/$CLICKUP_TASK_ID/attachment" \
    --header "Authorization: $CLICKUP_TOKEN" \
    --form "attachment=@$ATTACHMENT"
fi

echo "✅ Done reporting to ClickUp!"