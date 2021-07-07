class DevsistersDistcc < Formula
  desc "Distributed compiler client and server"
  homepage "https://github.com/devsisters/distcc/"
  url "https://github.com/devsisters/distcc/archive/refs/tags/v3.4-devsisters.1.tar.gz"
  sha256 "a475b5caca5b32ad5fdbc62cc0e0696096d5cdccd3ed5213c32e5e99ad0d1c3f"
  license "GPL-2.0-or-later"
  head "https://github.com/devsisters/distcc.git"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "python@3.9"

  resource "libiberty" do
    url "https://ftp.debian.org/debian/pool/main/libi/libiberty/libiberty_20210106.orig.tar.xz"
    sha256 "9df153d69914c0f5a9145e0abbb248e72feebab6777c712a30f1c3b8c19047d4"
  end

  def install
    # While libiberty recommends that packages vendor libiberty into their own source,
    # distcc wants to have a package manager-installed version.
    # Rather than make a package for a floating package like this, let's just
    # make it a resource.
    buildpath.install resource("libiberty")
    cd "libiberty" do
      system "./configure"
      system "make"
    end
    ENV.append "LDFLAGS", "-L#{buildpath}/libiberty"
    ENV.append_to_cflags "-I#{buildpath}/include"

    # Make sure python stuff is put into the Cellar.
    # --root triggers a bug and installs into HOMEBREW_PREFIX/lib/python2.7/site-packages instead of the Cellar.
    inreplace "Makefile.in", '--root="$$DESTDIR"', ""
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  
    # add compiler wrapper for convenient.
    # it takes compiler from env.
    (bin/"cc_wrapper").write <<~EOS
      #!/bin/sh
      exec #{bin}/distcc ${DISTCC_CC} "$@"
    EOS
    (bin/"cxx_wrapper").write <<~EOS
      #!/bin/sh
      exec #{bin}/distcc ${DISTCC_CXX} "$@"
    EOS
    system "chmod", "gu+x", "#{bin}/cc_wrapper", "#{bin}/cxx_wrapper"
  end

  test do
    system "#{bin}/distcc", "--version"
  end
end
