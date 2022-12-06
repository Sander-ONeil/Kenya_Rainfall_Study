#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (sanderoneil): " username
    username=${username:-sanderoneil}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100101-S000000-E235959.01.V06B.HDF5"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100101-S000000-E235959.01.V06B.HDF5 -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100101-S000000-E235959.01.V06B.HDF5 | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20100901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20101001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20101101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2010/3B-MO.MS.MRG.3IMERG.20101201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20110901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20111001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20111101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2011/3B-MO.MS.MRG.3IMERG.20111201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20120901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20121001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20121101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2012/3B-MO.MS.MRG.3IMERG.20121201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20130901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20131001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20131101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2013/3B-MO.MS.MRG.3IMERG.20131201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20140901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20141001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20141101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2014/3B-MO.MS.MRG.3IMERG.20141201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20150901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20151001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20151101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2015/3B-MO.MS.MRG.3IMERG.20151201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20160901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20161001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20161101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2016/3B-MO.MS.MRG.3IMERG.20161201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20170901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20171001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20171101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2017/3B-MO.MS.MRG.3IMERG.20171201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20180901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20181001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20181101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2018/3B-MO.MS.MRG.3IMERG.20181201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20190901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20191001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20191101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2019/3B-MO.MS.MRG.3IMERG.20191201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20200901-S000000-E235959.09.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20201001-S000000-E235959.10.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20201101-S000000-E235959.11.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2020/3B-MO.MS.MRG.3IMERG.20201201-S000000-E235959.12.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210101-S000000-E235959.01.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210201-S000000-E235959.02.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210301-S000000-E235959.03.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210401-S000000-E235959.04.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210501-S000000-E235959.05.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210601-S000000-E235959.06.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210701-S000000-E235959.07.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210801-S000000-E235959.08.V06B.HDF5
https://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGM.06/2021/3B-MO.MS.MRG.3IMERG.20210901-S000000-E235959.09.V06B.HDF5
EDSCEOF