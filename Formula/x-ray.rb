# typed: false
# frozen_string_literal: true

# Formula for x-ray - PDF redaction detection tool
class XRay < Formula
  include Language::Python::Virtualenv

  desc "Python library for finding bad redactions in PDF documents"
  homepage "https://github.com/freelawproject/x-ray"
  url "https://github.com/freelawproject/x-ray/archive/refs/tags/v0.3.5.tar.gz"
  sha256 "98361d4561e0afa0e142b8709ca4e20302baf2df83a104e45c8f7c467a919983"
  license "BSD-2-Clause"

  depends_on "pymupdf"
  depends_on "python@3.14"

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/b0/ee/9b19140fe824b367c04c5e1b369942dd754c4c5462d5674002f75c4dedc1/certifi-2024.8.30.tar.gz"
    sha256 "bec941d2aa8195e248a60b31ff9f0558284cf01a52591ceda73ea9afffd69fd9"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/f2/4f/e1808dc01273379acc506d18f1504eb2d299bd4131743b9fc54d7be4df1e/charset_normalizer-3.4.0.tar.gz"
    sha256 "223217c3d4f82c3ac5e29032b3f1c2eb0fb591b72161f86d93f5719079dae93e"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f1/70/7703c29685631f5a7590aa73f1f1d3fa9a380e654b86af429e0934a32f7d/idna-3.10.tar.gz"
    sha256 "12f65c9b470abda6dc35cf8e63cc574b1c52b11df2c86030af0ac09b01b13ea9"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/63/70/2bf7780ad2d390a8d301ad0b550f1581eadbd9a20f896afe06353c2a2913/requests-2.32.3.tar.gz"
    sha256 "55365417734eb18255590a9ff9eb97e9e1da868d4ccd6402399eaf68af20a760"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/ed/63/22ba4ebfe7430b76388e7cd448d5478814d3032121827c12a2cc287e2260/urllib3-2.2.3.tar.gz"
    sha256 "e7d814a81dad81e6caf2ec9fdedb284ecc9c73076b62654547cc64ccdcae26e9"
  end

  def install
    # Link to Homebrew's pymupdf installation
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources
    venv.pip_install buildpath

    # Create wrapper script named x-ray with PyMuPDF in PYTHONPATH
    site_packages = Language::Python.site_packages("python3.14")
    pymupdf_path = Formula["pymupdf"].opt_libexec/site_packages
    (bin/"x-ray").write_env_script libexec/"bin/xray",
                                   PATH:       "#{libexec}/bin:$PATH",
                                   PYTHONPATH: "#{pymupdf_path}:$PYTHONPATH"
  end

  test do
    # Test that the x-ray command exists
    assert_path_exists bin/"x-ray"

    # Test Python module can be imported with PyMuPDF support
    system libexec/"bin/python", "-c", "import xray; from fitz import Document"
  end
end
