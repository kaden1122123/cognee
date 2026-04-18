#!/bin/bash
# patch-cognee-fork.sh
# Apply Anthropic base_url patch to the fork

FORK_DIR="/home/clawuser/openclaw-workspace/others/cognee"
ADAPTER="$FORK_DIR/cognee/infrastructure/llm/structured_output_framework/litellm_instructor/llm/anthropic/adapter.py"
CLIENT="$FORK_DIR/cognee/infrastructure/llm/structured_output_framework/litellm_instructor/llm/get_llm_client.py"

echo "=== Patching AnthropicAdapter ==="
python3.14 - "$ADAPTER" << 'PYEOF'
import sys
adapter_path = sys.argv[1]
with open(adapter_path) as f:
    content = f.read()

old = """        self.aclient = instructor.patch(
            create=anthropic.AsyncAnthropic(api_key=self.api_key).messages.create,
            mode=instructor.Mode(self.instructor_mode),
        )"""

new = """        http_params = {"api_key": self.api_key}
        import os as _os
        if _os.getenv("ANTHROPIC_BASE_URL"):
            http_params["base_url"] = _os.getenv("ANTHROPIC_BASE_URL")

        self.aclient = instructor.patch(
            create=anthropic.AsyncAnthropic(**http_params).messages.create,
            mode=instructor.Mode(self.instructor_mode),
        )"""

if old not in content:
    print("ERROR: could not find target code in adapter.py")
    sys.exit(1)

content = content.replace(old, new)
with open(adapter_path, 'w') as f:
    f.write(content)
print("Adapter patched")
PYEOF

echo "=== Patching get_llm_client ==="
python3.14 - "$CLIENT" << 'PYEOF'
import sys
client_path = sys.argv[1]
with open(client_path) as f:
    content = f.read()

old = """        return AnthropicAdapter(
            llm_config.llm_api_key,
            llm_config.llm_model,
            max_completion_tokens,
            instructor_mode=llm_config.llm_instructor_mode.lower(),
            llm_args=llm_args,
        )

    elif provider == LLMProvider.CUSTOM:"""

new = """        import os as _os
        return AnthropicAdapter(
            llm_config.llm_api_key,
            llm_config.llm_model,
            max_completion_tokens,
            instructor_mode=llm_config.llm_instructor_mode.lower(),
            llm_args=llm_args,
        )

    elif provider == LLMProvider.CUSTOM:"""

if old not in content:
    print("ERROR: could not find target code in get_llm_client.py")
    sys.exit(1)

content = content.replace(old, new)
with open(client_path, 'w') as f:
    f.write(content)
print("get_llm_client.py patched")
PYEOF

echo "=== All patches applied ==="
