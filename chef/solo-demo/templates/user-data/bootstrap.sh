#!/bin/bash
#Chef-Solo BootStrap Script , this is the script that will be executed on first run it will:
# - Install chef-solo to the lastest version using opscode bash script
# - Create a cron job that will execute chef-solo every 30 min
# lets install chef-solo
#####TO DO######
# - Check if wget/curl return 0 bytes file and report that!
######################
REPO="https://s3.amazonaws.com/kiputch-solo"
CONFIG="/etc/solo-aws-config.conf"
SOLOBOOT="others/install.sh"
SOLOROLES="roles/roles.tar.gz"
SOLOSCRIPT="install.sh"
LOCAL="/usr/local/bootstrap"
LOG="/var/log/bootstrap.log"
SOLOLOG="/var/log/chef-solo-install.sh.log"
#############################
if [ ! -f "$CONFIG" ];then
  echo "ERROR: Config file was not found, exiting..."
  exit 1
else
  ID=`cat $CONFIG | grep json_attribs|awk 'BEGIN { FS=":" };{ print $2 }'`
   if [ -z $ID ];then
     error_n_exit "Could not get the instnace ID"
   else
   SOLORB="solorb/solo.rb_${ID}"
   fi
fi
#Functions
exists() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}
error_n_exit()
{

echo "`date`:ERROR $1 Exiting..." >> $LOG
/bin/cat /tmp/stderr >> $LOG

}
ok_n_cont()
{
echo "`date`:OK $1" >> $LOG
}
mkdir -p $LOCAL || error_n_exit "Could not create folders"
create_folders()
{
mkdir -p  /var/chef-solo/cache /var/chef-solo/cache/cookbooks /etc/chef /var/chef-solo/roles /var/chef-solo/check-sum
if [ "$?" == "0" ];then
  return 0
else
  return 1
fi
}
do_wget() 
{
  echo "trying wget..."
  wget -O "$1" "$2" 2>/tmp/stderr
  rc=$?
  if [ "$rc" != "0" ]; then
    error_n_exit "WGET returned ERROR check $LOG for full stacktrace"
  fi 
  return 0
}

# do_curl URL FILENAME
do_curl() 
{
  echo "trying curl..."
  curl -sL -D /tmp/stderr "$1" > "$2"
  rc=$?

   if [ "$rc" != "0" ]; then
    error_n_exit "CURL returned ERROR check $LOG for full stacktrace"
   fi

  return 0
}
#Create Folders
create_folders
 if [ "$?" != "0" ];then
   error_n_exit "Failed to create folders"
 else
   ok_n_cont "Created Folders"
 fi
#Get Chef-Solo Install Script , Chef-Solo generated configuration files
exists "wget"
if [ "$?" == "0" ];then
  do_wget "$LOCAL/$SOLOSCRIPT" "$REPO/$SOLOBOOT"
  do_wget "/etc/chef/solo.rb" "$REPO/$SOLORB"
  do_wget "/var/chef-solo/roles/roles.tar.gz" "$REPO/$SOLOROLES"
  cd /var/chef-solo/roles/ || error_n_exit "could not change dir to roles"
  tar xvfz roles.tar.gz    || error_n_exit "could not extract roles.tar.gz"
elif [ "$?" == "1" ];then 
  exists "curl"
    if [ "$?" == "0" ];then
      do_curl "$REPO/$SOLOBOOT" "$LOCAL/$SOLOSCRIPT"
      do_curl "$REPO/$SOLORB" "/etc/chef/solo.rb"
      do_curl "$REPO/$SOLOROLES" "/var/chef-solo/roles/roles.tar.gz"
      /usr/bin/cd /var/chef-solo/roles/ || error_n_exit "could not change dir to roles"
      /use/bin/tar xvfz roles.tar.gz    || error_n_exit "could not extract roles.tar.gz"
    fi 
fi

    chmod +x $LOCAL/$SOLOSCRIPT || error_n_exit "Could not set +x to to $LOCAL/$SOLOSCRIPT"
    source $LOCAL/$SOLOSCRIPT 2>&1 >> $SOLOLOG
     if [ "$?" == "0" ];then
      ok_n_cont "Looks like Chef-Solo Was Installed Successfully Check $SOLOLOG for more info"
     else
      error_n_exit "Chef-solo failed to install, check $SOLOLOG for more info"
     fi
#
exit 0