post_pkg_postinst() {
	[[ -z ${ROOT} || ${ROOT} == / ]] || return 0
	command -v dracut >/dev/null 2>&1 && command -v lsinitrd >/dev/null 2>&1 || return 0
	[[ -n ${KV_FULL} ]] && (( ${#_MODULES_INSTALL[@]} )) || return 0

	local image="/boot/initramfs-genkernel-x86_64-${KV_FULL}"
	[[ -e ${image} ]] || return 0

	local mod names=()
	for mod in "${!_MODULES_INSTALL[@]}"; do
		mod=${mod##*/}
		names+=( "${mod%.ko}" )
	done

	local files drivers
	files="/($(IFS='|'; echo "${names[*]}"))\.ko"
	drivers="^[[:space:]]*(force|add)_drivers\+?=.*[\" ]($(IFS='|'; echo "${names[*]//-/_}"))[\" ]"

	if lsinitrd "${image}" 2>/dev/null | grep -Eq "${files}" \
		|| grep -Eqs "${drivers}" /etc/dracut.conf /etc/dracut.conf.d/*.conf ; then
		local args=( -H -f -o systemd -o systemd-initrd -o systemd-networkd -o dracut-systemd )
		has_version "sys-kernel/linux-argent[plymouth]" || args+=( -o plymouth )
		einfo "Regenerating ${image} for the new ${PN} modules"
		dracut "${args[@]}" --early-microcode --kver="${KV_FULL}" "${image}" \
			|| ewarn "dracut failed, rerun it by hand for ${KV_FULL}"
	fi
}
