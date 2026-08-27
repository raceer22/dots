dnf repoquery --userinstalled --qf "%{name}\n" | sort >dnf-packages.txt
flatpak list --app --columns=application | sort >flatpak-packages.txt
