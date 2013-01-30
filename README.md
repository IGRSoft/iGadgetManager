iGadget Manager
==============

iPhone, iPad and iPod Manager!

iGadgetManager is an utility to manage iDevices on Mac OS X 10.7.x-10.8.x.

<img src="https://raw.github.com/iKorich/iGadgetManager/master/screenshot.png">

Credits
-------------

Developer: Vitalii (Korich) Parovishnyk 

Building
-------------

Fetch your dependencies. Because these vary from distro to distro, I won't list specific packages here, that said you need developement packages for: libimobiledevice, libplist, libusb, usbmuxd, gnutls, libxml2, libglib2, libusb and libzip.

For libxml use "./configure --without-python --without-lzma".

Then:

* git clone git://github.com/boxingsquirrel/ideviceactivate.git
* cd ideviceactivate
* make
* sudo make install

If you have some problems, then visit http://www.libimobiledevice.org for more info

Now you can build it in Xcode!

Running
-------------

Just do double click ;)

Notes
-------------

Big Thanks for Evilence for App Name!

Licence
-------------

This application is free open source software and licensed under the LGPL 2.1.