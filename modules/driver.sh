#!/bin/sh

# A hudson build driver for Titanium Mobile Modules

#export PATH=/bin:/usr/bin::$PATH
export PATH=/home/hudson/linux_slave/bin:/opt/apache-ant/bin:$PATH
export PKG_CONFIG_PATH=/home/hudson/linux_slave/lib/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/home/hudson/linux_slave/lib

GIT_BRANCH=$1
GIT_REVISION=`git log --pretty=oneline -n 1 | sed 's/ .*//' | tr -d '\n' | tr -d '\r'`
#VERSION=`python $TITANIUM_BUILD/common/get_version.py | tr -d '\r'`
PLATFORM=`python -c "import platform; print ({'Darwin':'osx','Windows':'win32','Linux':'linux'})[platform.system()]" | tr -d '\r' | tr -d '\n'`
TIMESTAMP=`date +'%Y%m%d%H%M%S'`

if [ "$PYTHON" = "" ]; then
	PYTHON=python
fi

# Android modules

#export TITANIUM_BUILD=/home/hudson/Source/titanium_build
#export WORKSPACE=/home/hudson/linux_slave/stage/titanium_mobile_modules

for MODULE in `ls $WORKSPACE/android`; do
	MIN_SDK=`grep minsdk $WORKSPACE/android/$MODULE/manifest | cut -f2 -d' '`
	sed s/TITANIUM_VERSION/$MIN_SDK/ $TITANIUM_BUILD/modules/build.properties.template > $WORKSPACE/android/$MODULE/build.properties
	cd $WORKSPACE/android/$MODULE
	echo building $MODULE...
	MOD_TIME_PREV=`ls -l --time-style=+'%Y%m%d%H%M%S' dist/*\.zip | awk '{print $6}'`
	ZIP=`ls dist/*\.zip`
	rm $ZIP
	ant 2>&1 > ant.log
	MOD_TIME_POST=`ls -l --time-style=+'%Y%m%d%H%M%S' dist/*\.zip | awk '{print $6}'`
	# check if zip was updated
	#echo $MOD_TIME_PREV
	#echo $MOD_TIME_POST
	#if [ "$MOD_TIME_PREV" = "$MOD_TIME_POST" ]; then continue; fi
	ZIP=`ls dist/*\.zip`
	if [ -z "$ZIP" ]; then continue; fi
	STAMPED_ZIP=`echo $ZIP| sed "s/\/\(.*\).zip/\/\1-$MOD_TIME_POST.zip/"`
	cp $ZIP $STAMPED_ZIP
	$PYTHON $TITANIUM_BUILD/common/s3_uploader.py modules $STAMPED_ZIP $GIT_BRANCH $GIT_REVISION $BUILD_URL
	rm $STAMPED_ZIP
done

#$PYTHON $TITANIUM_BUILD/common/s3_cleaner.py modules $GIT_BRANCH
