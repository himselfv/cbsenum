# CBSEnum #

CBSEnum is a tool to view and manage Windows Component-Based Servicing packages.

Component-Based Servicing is a technology since Windows Vista which most resembles Linux-style package managers. It builds upon WinSxS (Side by side assemblies) to allow installation, deinstallation and updating of numerous Windows components independently.

It presents a moderately componentized view into Windows and allows uninstalling parts of system which outside of Windows Embedded were previously seen as monolithic.

In Windows, this technology is hidden from general public. There's a command-line tool dism.exe to manage CBS packages, but most packages are marked as hidden even from DISM.

![CBSEnum screenshot](https://bitbucket.org/himselfv/cbsenum/raw/tip/Docs/cbsenum-0.8-screen.png)

CBSEnum is a graphical interface for DISM which presents packages in a visually simple format, allows to uninstall or mass-uninstall any. It also shows hidden packages, lets you make them visible or restore to original visibility state.

### Requirements and warnings ###

CBSEnum must be run as administrator.

Before anything can be done with packages, you will have to take ownership of `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing` registry key and all subkeys and give yourself write permissions. CBSEnum can do this for you: choose "Edit -> Take Ownership".

Before most packages can be deleted, they have to be detached from their mothership package ("Windows Home", "Windows Professional" or "Windows Enterprise"). This can be done with [install_wim_tweak tool](http://www.wincert.net/forum/topic/12021-install-wim-tweakexe/) but now CBSEnum supports this too: "Edit -> Decouple all packages".

Before DISM will work with most packages, they have to be made DISM-visible. This can be done from CBSEnum by right-clicking any package and doing "Visibility -> Make visible". You can also make all packages Visible from Edit menu.

CBSEnum preserves original package visibility in the same way instal_wim_tweak does, in DefVis keys.

When uninstalling packages, exert your usual caution. Uninstalled packages cannot be installed back without their source cabs, which most people don't have. Save for reinstalling the OS, your best bet would be system repair from installation media.

### Bulk removal ###

Starting with 0.9, CBSEnum supports bulk removal scripts. Each line is a package mask:

```
# Telemetry
Microsoft-OneCore-AllowTelemetry*
Microsoft-Windows-Prerelease*
Microsoft-Windows-DiagTrack*
# Microsoft-WindowsFeedback*		# Feedback is a useful app to have, but may be seen as telemetry
Microsoft-OneCore-TroubleShooting*	# Some consider this also part of telemetry.
Microsoft-Windows-TroubleShooting*
Microsoft-Windows-ContactSupport*	# Contact Microsoft support
```

Such scripts, listing all that you feel needs to be removed with comments about the reasons, can be tested in a virtual machine until a satisfying configuration is achieved and then deployed to the actual target.