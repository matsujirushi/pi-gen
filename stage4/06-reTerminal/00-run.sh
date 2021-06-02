#!/bin/bash -e


if [ "X$GIT_MODULE" != "X" ]; then
	MODULE_PATH=/tmp/seeed-linux-dtoverlays
	${PROXYCHAINS} git clone ${GIT_MODULE} "${ROOTFS_DIR}${MODULE_PATH}"
	${PROXYCHAINS} wget https://goo.gl/htHv7m -O "${ROOTFS_DIR}/boot/dt-blob.bin"

	on_chroot << EOF
cd ${MODULE_PATH}
sudo ./scripts/reTerminal.sh
EOF

	rm -rfv "${ROOTFS_DIR}${MODULE_PATH}"
fi

if [ "X$GIT_DEMO" != "X" ]; then
	DEMO_PATH=/home/${FIRST_USER_NAME}/Seeed_Python_ReTerminalQt5Examples
	${PROXYCHAINS} git clone ${GIT_DEMO} "${ROOTFS_DIR}${DEMO_PATH}"

	on_chroot << EOF
mkdir -pv /home/${FIRST_USER_NAME}/Desktop/
cp -v ${DEMO_PATH}/src/r2.desktop /home/${FIRST_USER_NAME}/Desktop/
sudo chown -vR ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}
EOF

	rm -rfv "${ROOTFS_DIR}${DEMO_PATH}"/.git
fi

if [ -f "purges" ]; then
	log "Begin ${SUB_STAGE_DIR}/purges"
	PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "purges")"
	if [ -n "$PACKAGES" ]; then
		on_chroot << EOF
apt-get autoremove --purge -y $PACKAGES
EOF
		if [ "${USE_QCOW2}" = "1" ]; then
			on_chroot << EOF
apt-get clean
EOF
		fi
	fi
	log "End ${SUB_STAGE_DIR}/purges"
fi

if [ -f "remove" ]; then
	log "Begin ${SUB_STAGE_DIR}/remove"
	PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "remove")"
	on_chroot << EOF
rm -rfv $PACKAGES
EOF
	log "End ${SUB_STAGE_DIR}/remove"
fi

if [ -f "packages" ]; then
	log "Begin ${SUB_STAGE_DIR}/packages"
	PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "packages")"
	if [ -n "$PACKAGES" ]; then
		on_chroot << EOF
apt-get -o APT::Acquire::Retries=3 install -y $PACKAGES
EOF
		if [ "${USE_QCOW2}" = "1" ]; then
			on_chroot << EOF
apt-get clean
EOF
		fi
	fi
	log "End ${SUB_STAGE_DIR}/packages"
fi

if [ "${COPY_FILES}" = "1" ]; then
	mkdir -p ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/libfm \
		&& cp -fv ./files/libfm.conf "$_"
	on_chroot << EOF
sudo chown -vR ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}/.config
EOF

	SCHEMAS_PATH=/usr/share/glib-2.0/schemas/
	cp -fv ./files/20_onboard-default-settings.gschema.override "${ROOTFS_DIR}${SCHEMAS_PATH}"
	on_chroot << EOF
glib-compile-schemas ${SCHEMAS_PATH}
EOF
fi
