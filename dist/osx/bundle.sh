#!/bin/sh

case "$(uname)" in
    Darwin) ;;
    *)
        echo "Unsupported system type: $(uname)"
        exit 1
        ;;
esac

cd $(dirname $0)/../..

rm -f src/spek
make || exit 1
strip src/spek
upx src/spek

cd dist/osx
rm -fr Spek.app
mkdir -p Spek.app/Contents/MacOS
mkdir -p Spek.app/Contents/Resources
mv ../../src/spek Spek.app/Contents/MacOS/Spek
cp Info.plist Spek.app/Contents/
cp Spek.icns Spek.app/Contents/Resources/

# mv share/locale/{cs,da,de,eo,es,fr,it,ja,nl,pl,pt_BR,ru,sv,uk,zh_CN,zh_TW} share/locale_/

# Make DMG image
VOLUME_NAME=Spek
DMG_APP=Spek.app
DMG_FILE=$VOLUME_NAME.dmg
MOUNT_POINT=$VOLUME_NAME.mounted

rm -f $DMG_FILE
rm -f $DMG_FILE.master

# Compute an approximated image size in MB, and bloat by 1MB
image_size=$(du -ck $DMG_APP | tail -n1 | cut -f1)
image_size=$((($image_size + 5000) / 1000))

echo "Creating disk image (${image_size}MB)..."
hdiutil create $DMG_FILE -megabytes $image_size -volname $VOLUME_NAME -fs HFS+ -quiet || exit $?

echo "Attaching to disk image..."
hdiutil attach $DMG_FILE -readwrite -noautoopen -mountpoint $MOUNT_POINT -quiet

echo "Populating image..."

cp -Rp $DMG_APP $MOUNT_POINT

find $MOUNT_POINT -type d -iregex '.*\.svn$' &>/dev/null | xargs rm -rf

cd $MOUNT_POINT
ln -s /Applications " "
cd ..

cp DS_Store $MOUNT_POINT/.DS_Store

echo "Detaching from disk image..."
hdiutil detach $MOUNT_POINT -quiet

mv $DMG_FILE $DMG_FILE.master

echo "Creating distributable image..."
hdiutil convert -quiet -format UDBZ -o $DMG_FILE $DMG_FILE.master

echo "Done."

if [ ! "x$1" = "x-m" ]; then
    rm $DMG_FILE.master
fi

cd ../..
