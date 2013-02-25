#!/usr/bin/env sh
#
# Automatically upload every files in a given directory to an FTP server keeping
# file hierarchy. If the upload is successful, the files and directories are
# removed.
# Please edit /usr/local/etc/autoftpupload.conf to configure the script.
# 
# Required package: ncftp
#
# You might want to prevent duplicate cron jobs running, since an FTP upload
# may take time. Use the following line when editing crontab (`crontab -e`):
#     */10 * * * * flock -n /var/lock/autoftpupload.lock /usr/local/bin/autoftpupload.sh >> /var/log/autoftpupload.sh.log 2>&1
#
# Author: Morgan Courbet



set -u

DEFAULT_CONF_FILE=/usr/local/etc/autoftpupload.conf

# for logging purpose
alias timestamp="date +[%Y-%m-%d\ %T]"

log() {
	echo "$(timestamp) $1"
}

error() {
	log "ERROR: $1" >&2
}

# list the files to be uploaded
files_to_upload () {
	find "$1" -type f | sort
}

# remove base path from full path
# `get_relative_path /home/user/data /home/user` will return data
get_relative_path () {
	if [ "$#" -ne 2 ]; then
		error "get_relative_path needs 2 arguments. $# provided."
		return 1;
	fi

	local full_path="$1"
	local base_path="$2"
	echo "$full_path" | sed -r "s:^$base_path/?::"
}

# upload the file and return the exit value of ncftpput
upload_file () {
	# remove file name from full path (e.g. /home/user/data/file -> /home/user/data)
	local containing_dir="$(dirname "$1")"
	# remove base folder from full path (e.g. /home/user/data/ -> data)
	local relative_remote_home="$(get_relative_path "$containing_dir" "$LOCAL_HOME")"
	ncftpput -V -m -DD -u "$REMOTE_USER" -p "$REMOTE_PASSWORD" "$REMOTE_HOST" "$REMOTE_HOME/$relative_remote_home" "$1"
	return $?
}

# remove file directory if empty
rm_empty_dir () {
	# remove file name from full path (e.g. /home/user/data/file -> /home/user/data)
	local containing_dir="$(dirname "$1")"
	if [ -z "$(ls -A "$containing_dir")" ]; then
		# remove base folder from full path (e.g. /home/user/data/ -> data)
		local relative_dir="$(get_relative_path "$containing_dir" "$LOCAL_HOME")"
		cd "$LOCAL_HOME"
		rmdir --ignore-fail-on-non-empty -p "$relative_dir"
		cd -
	fi
}





# load configuration file
if [ "$#" -gt 0 ]; then
	conf_file=$(readlink -e "$1")
	if [ -f "$conf_file" ]; then
		log "Specific configuration file provided: '$conf_file'"
		. "$conf_file"
	else
		error "The file '$1' does not exist."
		exit 1
	fi
else
	. "$DEFAULT_CONF_FILE"
fi

# check if all required parameters are set
if [ -z "$LOCAL_HOME" ] ||
		[ -z "$REMOTE_HOST" ] ||
		[ -z "$REMOTE_PORT" ] ||
		[ -z "$REMOTE_USER" ] ||
		[ -z "$REMOTE_PASSWORD" ] ||
		[ -z "$REMOTE_HOME" ]; then
	error "Please check configuration."
	exit 1
fi

# processing each file found in the local home directory
files_to_upload "$LOCAL_HOME" | while read newfile
do
	if echo "$newfile" | grep -qe "$IGNORED_FOLDER_NAMES_PATTERN"; then
		log "Skipped '$newfile'"
		# step to the next file
		continue
	fi

	log "Trying to upload '$newfile' to '$REMOTE_HOST:$REMOTE_PORT$REMOTE_HOME'"
	upload_file "$newfile"
	r_upload_file=$?

	if [ $r_upload_file -ne 0 ]; then
		error "Failed to upload '$newfile' to '$REMOTE_HOST:$REMOTE_PORT$REMOTE_HOME'. ncftpput returned error code $r_upload_file. man ncftpput for more details."
		# no further action on the current file
		continue
	fi

	log "Successfully transferred '$newfile'"

	rm_empty_dir "$newfile"
done

