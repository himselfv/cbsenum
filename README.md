# CBSEnum #

CBSEnum is a tool to view and manage Windows Component-Based Servicing packages.

Component-Based Servicing is a technology since Windows Vista which most resembles Linux-style package managers. It builds upon WinSxS (Side by side assemblies) to allow installation, deinstallation and updating of numerous Windows components independently.

It presents a moderately componentized view into Windows and allows uninstalling parts of system which outside of Windows Embedded were previously seen as monolithic.

In Windows, this technology is hidden from general public. There's a command-line tool dism.exe to manage CBS packages, but most packages are marked as hidden even from DISM.

![CBSEnum screenshot](https://bitbucket.org/himselfv/cbsenum/raw/tip/Docs/cbsenum-0.8-screenshot.png)

CBSEnum is a graphical interface for DISM which presents packages in a visually simple format, allows to uninstall or mass-uninstall any. It also shows hidden packages, lets you make them visible or restore to original visibility state.

### Requirements and warnings ###

CBSEnum must be run as administrator.

Before anything can be done with packages, you will have to take ownership of `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing` registry key and all subkeys and give yourself write permissions. At this time CBSEnum can't do this for you.

Before most packages can be deleted, they have to be detached from their mothership package ("Windows Home", "Windows Professional" or "Windows Enterprise"). This is done in registry, [install_wim_tweak tool](http://www.wincert.net/forum/topic/12021-install-wim-tweakexe/) can do this for you. At this time CBSEnum cannot do this for you.

Before DISM will work with most packages, they have to be made DISM-visible. This can be done from CBSEnum by right-clicking any package and doing "Visibility -> Make visible". You can also make all packages Visible from Edit menu.

CBSEnum preserves original package visibility in the same way instal_wim_tweak does, in DefVis keys.

When uninstalling packages, exert your usual caution. Uninstalled packages cannot be installed back without their source cabs, which most people don't have. Save for reinstalling the OS, your best bet would be system repair from installation media.