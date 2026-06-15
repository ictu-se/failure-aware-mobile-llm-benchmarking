# Phone returned to user checkpoint

Time: 2026-06-12 09:09:27 +07:00

Stopped the active phone NPU controlled matrix and collectors because the user needs the phone.

Partial result before stopping:
- short/NPU completed with summary.
- medium/NPU was stuck/no benchmark CSV; it was interrupted and should be treated as partial/invalid unless later summarized carefully.
- long/NPU was active when the stop request came; treat as interrupted/invalid unless valid CSV exists.
