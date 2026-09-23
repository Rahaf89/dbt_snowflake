{% macro simulate_alert_failure() %}
    {% if var('allow_alert_test', false) %}
        {{ exceptions.raise_compiler_error("Intentional alert test failure: notification delivery validation.") }}
    {% else %}
        {{ log("Alert test skipped. Pass --vars '{allow_alert_test: true}' only in a temporary alert-test job.", info=True) }}
    {% endif %}
{% endmacro %}
