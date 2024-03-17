## TODO List
This is a list of todo items, mostly in the order in which they will be implemented.

- Restructure code to be cleaner and more organized.
- Remove all lint ignore_for_file comments.
- Rename UvcLib to UVCLib since UVCControl is that way, or rename UVCControl to UvcControl.
- Finish cleaning up uvc_example.dart for release.
- Finish README.
- Fix the libusb exit errors.
- Publish first version as 1.0.0 on pub.dev.
- Determine how to know if a control, like zoom, is supported.
- Finish using debugLogging everywhere.
- All constants and functions should be moved inside of some class or enum.
- Add support for Linux.
- Add support for video streaming.

## Exit errors from libusb
```
[ 0.198460] [0014c208] libusb: debug [libusb_exit]  
[ 0.198467] [0014c208] libusb: debug [libusb_unref_device] destroy device 0.5
[ 0.198470] [0014c208] libusb: debug [libusb_unref_device] destroy device 0.4
[ 0.198473] [0014c208] libusb: debug [libusb_unref_device] destroy device 0.3
[ 0.198475] [0014c208] libusb: debug [libusb_unref_device] destroy device 0.2
[ 0.198476] [0014c208] libusb: debug [libusb_unref_device] destroy device 0.1
[ 0.198478] [0014c208] libusb: debug [libusb_unref_device] destroy device 20.6
[ 0.198480] [0014c208] libusb: debug [libusb_unref_device] destroy device 1.2
[ 0.198482] [0014c208] libusb: debug [libusb_unref_device] destroy device 20.5
[ 0.198506] [0014c209] libusb: debug [darwin_event_thread_main] darwin event thread exiting
[ 0.198613] [0014c208] libusb: error [darwin_cleanup_devices] device still referenced at libusb_exit
[ 0.198797] [0014c208] libusb: error [darwin_cleanup_devices] device still referenced at libusb_exit
[ 0.199063] [0014c208] libusb: error [darwin_cleanup_devices] device still referenced at libusb_exit
[ 0.199507] [0014c208] libusb: debug [usbi_remove_event_source] remove fd 6
[ 0.199522] [0014c208] libusb: warning [libusb_exit] device 20.10 still referenced
[ 0.199524] [0014c208] libusb: warning [libusb_exit] device 20.9 still referenced
[ 0.199526] [0014c208] libusb: warning [libusb_exit] device 20.8 still referenced
[ 0.199528] [0014c208] libusb: warning [libusb_exit] application left some devices open
```