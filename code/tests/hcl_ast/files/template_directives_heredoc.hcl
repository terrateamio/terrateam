report = <<-EOT
%{ if enabled ~}
service: ${name}
%{~ endif }
users:
%{ for u in users ~}
  - ${u.name} (${u.role})
%{ endfor ~}
EOT
