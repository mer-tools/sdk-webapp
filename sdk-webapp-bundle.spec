Name:           sdk-webapp-bundle
Summary:        Bundle of gems used by sdk-webapp
Version:        0.4.0
Release:        1
#
Group:          Development/Languages/Ruby
License:        GPLv2+ or Ruby (see gems)
#
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
# This is the BR for all enclosed gems
BuildRequires:  rubygem-bundler git gcc-c++ openssl-devel pkgconfig
Requires:       rubygem-bundler
#
Url:            https://wiki.merproject.org/wiki/Platform_SDK
# DEVSRC=/mer/mer/devel/mer-sdk/sdk-webapp-bundle ./update-pkg.sh

Source0: Gemfile
Source1: Gemfile.lock
Source2: sdk-webapp-bundle.rpmlintrc
Source3: haml-3.1.7.gem
Source4: i18n-0.6.1.gem
Source5: i18n-translators-tools-0.2.4.gem
Source6: json-1.5.4.gem
Source7: mime-types-1.19.gem
Source8: open4-1.3.0.gem
Source9: rack-1.4.1.gem
Source10: rack-protection-1.2.0.gem
Source11: rest-client-1.6.7.gem
Source12: sass-3.2.1.gem
Source13: sinatra-1.3.3.gem
Source14: tilt-1.3.3.gem
Source15: ya2yaml-0.31.gem
# SourceEnd : This line is needed to make the script in the README work

Summary:        Gems needed to run sdk-webapp
%description

This package is the bundle of gems needed to run the Mer SDK webapp

%prep
# We use the Gemfile, Gemfile,lock and rpmlintrc
cp %{SOURCE0} .
cp %{SOURCE1} .
cp %{SOURCE2} .

mkdir -p vendor/cache;
for file in %{lua: for i, p in ipairs(sources) do print(p.." ") end}; do if [[ ${file: -3:3} == "gem" ]]; then cp $file vendor/cache; elif [[ ${file: -3:3} == "bz2" ]]; then tar xf $file; fi; done

%build
%install
mkdir -p %{buildroot}/%{_libdir}/%{name}
bundle install --local --standalone --deployment --binstubs=%{buildroot}/%{_bindir}/ --no-cache --shebang=%{_bindir}/ruby
find . -name .gitignore -print0 | xargs --no-run-if-empty -0 rm

# Install everything we just built
cp -al . %{buildroot}/usr/lib/%{name}/

# Don't install the rpmlintrc
rm %{buildroot}/usr/lib/%{name}/$(basename %{SOURCE2})

# Change #!/usr/local/bin/ruby to #!/usr/bin/ruby
fgrep -rl "usr/local/bin" %{buildroot} | xargs --no-run-if-empty sed -i -e 's_/usr/local/bin_/%{_bindir}_'g
# Change ../../../../../BUILD to {%_libdir}/%{name}
fgrep -rl "../../../../../BUILD" %{buildroot} | xargs --no-run-if-empty sed -i -e 's_../../../../../BUILD_%{_libdir}/%{name}_'g
# Remove references to buildroot
fgrep -rl "%{buildroot}" %{buildroot} | xargs --no-run-if-empty sed -i -e 's_%{buildroot}__'g

%files
%defattr(-,root,root,-)
%{_libdir}/%{name}/
%{_bindir}

