Summary: Uravo command line collection and control scripts.
Name: uravo-agent
Version: 0.0.1
Release: 1
Epoch: 0
License: GPL
URL: http://www.minorimpact.com
Group: Applications/System
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch

Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

Requires: perl-Uravo

%description
Uravo.

%prep
%setup

%build

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p ${RPM_BUILD_ROOT}
cp -r ${RPM_BUILD_DIR}/%{name}-%{version}/* ${RPM_BUILD_ROOT}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/*


# Changelog - update this with every build of the package
%changelog
* Tue Aug 08 2017 <pgilan@minorimpact.com> 0.0.1-1
- Initial build.
