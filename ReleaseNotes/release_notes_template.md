{% set categories = [
    'selections', 'Configuration',
    'Decoding', 'Tracking', 'PV finding', 'VP', 'UT', 'FT', 'Muon', 'Calo', 'RICH', 'Jets',
    'PID', 'Composites', 'Filters', 'Functors',
    'Event model', 'Persistency',
    'MC checking', 'Monitoring', 'Luminosity',
    'Core', 'Conditions', 'Utilities',
    'Simulation',  'Tuples', 'Accelerators',
    'Flavour tagging',
    'Build', 'integration',
    ] -%}
{% set used_mrs = [] -%}
{% macro section(labels, mrs=merge_requests, used=used_mrs, indent='', highlight='highlight') -%}
{% for mr in order_by_label(select_mrs(mrs, labels, used), categories) -%}
  {% set mr_labels = categories|select("in", mr.labels)|list -%}
{{indent}}- {% if mr_labels %}{{mr_labels|map('label_ref')|join(' ')}} | {% endif -%}
    {{mr.title|sentence}}, {{mr|mr_ref(project_fullname)}} (@{{mr.author.username}}){% if mr.issue_refs %} [{{mr.issue_refs|join(',')}}]{% endif %}{% if highlight in mr.labels %} :star:{% endif %}
{# {{mr.description|mdindent(2)}} -#}
{% endfor -%}
{% endmacro -%}
{{date}} {{project}} {{version}}
===

This version uses
{{project_deps[:-1]|join(',\n')}} and
{{project_deps|last}}.

This version is released on `master` branch.
Built relative to {{project}} [{{project_prev_tag}}](../-/tags/{{project_prev_tag}}), with the following changes:

### New features ~"new feature"

{{ section(['new feature']) }}

### Fixes ~"bug fix" ~workaround

{{ section(['bug fix', 'workaround']) }}

### Enhancements ~enhancement

{{ section(['enhancement']) }}

### Code cleanups and changes to tests ~modernisation ~cleanup ~testing

{{ section(['cleanup', 'modernisation', 'testing']) }}

### Documentation ~Documentation

{# Collect documentation independently, may lead to repeated entries -#}
{{ section(['Documentation'], used=None) }}
{# Mark as used such documentation does not appear under Other -#}
{% set dummy = section(['Documentation']) -%}

### Other

{{ section([[]]) }}
