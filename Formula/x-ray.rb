# typed: false
# frozen_string_literal: true

# Formula for x-ray - PDF redaction detection tool
class XRay < Formula
  include Language::Python::Virtualenv

  desc "Python library for finding bad redactions in PDF documents"
  homepage "https://github.com/freelawproject/x-ray"
  url "https://github.com/freelawproject/x-ray/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "0780c69dd8aa4af79fc34b69d81ecde7ba8e0a8f7c0a684ed87c7cae523a737d"
  license "BSD-2-Clause"

  depends_on "mupdf"
  depends_on "pymupdf"
  depends_on "python@3.15"

  # Metadata for `brew update-python-resources`, which regenerates the
  # resource blocks below by resolving this formula by NAME from the
  # tap (scripts/update-x-ray-resources.sh stages the tap copy; the
  # Renovate Resources workflow runs it on Renovate version-bump PRs).
  # PyMuPDF is excluded because the `pymupdf` formula dependency above
  # provides the fitz bindings instead of a vendored pip resource (see
  # the pymupdf_python note below). python@3.15 is listed so
  # --install-dependencies can satisfy the resolver's pip.
  pypi_packages package_name:     "x-ray",
                exclude_packages: ["PyMuPDF"],
                dependencies:     ["python@3.15"]

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/a1/98/7e457a3b014976887a050561955c0b76e1e7e2d6e27b78ecef2ef80518f2/anyio-4.16.0.tar.gz"
    sha256 "59bb03251907983d1603d27c3087ddb1e93299ea2163adcdba37899a4fb12ffb"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "h2" do
    url "https://files.pythonhosted.org/packages/e7/85/7c366e69d84c17bb778fe41419e1fbcce3033d5b7ce29bbffff0a98b859f/h2-4.4.1.tar.gz"
    sha256 "4e866ffb1a869ae14dd9b5e6beb5c24a13da0495ad72b65925ded182521c1516"
  end

  resource "hpack" do
    url "https://files.pythonhosted.org/packages/26/5b/fcabf6028144a8723726318b07a32c2f3314acdff6265743cf08a344b18e/hpack-4.2.0.tar.gz"
    sha256 "0895cfa3b5531fc65fe439c05eb65144f123bf7a394fcaa56aa423548d8e45c0"
  end

  resource "httpcore2" do
    url "https://files.pythonhosted.org/packages/c0/61/afa9d6b7452f9eca73f73d45324eb0bb52f098fd5e6049bf6b8263be9b4e/httpcore2-2.16.0.tar.gz"
    sha256 "c72cd0413563b17e1cd8354677dff887466f8ec2551679759e93126534428643"
  end

  resource "httpx2" do
    url "https://files.pythonhosted.org/packages/43/73/5ca2cedf5e4e50423d1c258877865a6b62793633b561c58499f8aeb33b7e/httpx2-2.16.0.tar.gz"
    sha256 "0d54c98128e8f2ff7fbbde0fca8c359e5f032edeaaaac443cdb7f31f685bcd7f"
  end

  resource "hyperframe" do
    url "https://files.pythonhosted.org/packages/02/e7/94f8232d4a74cc99514c13a9f995811485a6903d48e5d952771ef6322e30/hyperframe-6.1.0.tar.gz"
    sha256 "f630908a00854a7adeabd6382b43923a4c4cd4b821fcb527e6ab9e15382a3b08"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/f5/08/8eea9d4b8302028f3abb2c0813953f7aec26d33b7a8960ed760e65ff29fa/idna-3.20.tar.gz"
    sha256 "a7db850025b95ded1eae8a46181a1a6c56c92c96f0e2b005d9ff8dc0210cab44"
  end

  resource "truststore" do
    url "https://files.pythonhosted.org/packages/ee/9f/c5201d42a484c061e528825fc8e2d565f5abd50a4ced6fb7d29c4ec99b2b/truststore-0.10.5.tar.gz"
    sha256 "30d36967ccaded5cbb38d602c433f53600036c79d502f4533a49b60a03bbefcd"
  end

  # Homebrew's prebuilt pymupdf/mupdf Python bindings are built by
  # homebrew-core against this Python; the venv below and the PYTHONPATH
  # paths must move together whenever core migrates pymupdf to a newer
  # Python (see issue #60 for what happened when this linkage was left
  # implicit).
  def pymupdf_python
    "python3.15"
  end

  def pymupdf_site_packages
    %w[mupdf pymupdf].map { |name| formula_opt_prefix(name)/Language::Python.site_packages(pymupdf_python) }
  end

  def install
    venv = virtualenv_create(libexec, pymupdf_python)
    venv.pip_install resources
    venv.pip_install buildpath

    # Create wrapper script named x-ray with PyMuPDF in PYTHONPATH
    pymupdf_path = pymupdf_site_packages.join(":")
    (bin/"x-ray").write_env_script libexec/"bin/xray",
                                   PATH:       "#{libexec}/bin:$PATH",
                                   # ${VAR:+:$VAR} appends only when VAR is set; a bare $VAR
                                   # would leave an empty entry that Python treats as cwd
                                   PYTHONPATH: "#{pymupdf_path}${PYTHONPATH:+:$PYTHONPATH}"
  end

  test do
    # Test that the x-ray command exists
    assert_path_exists bin/"x-ray"

    # Mirror the wrapper's PYTHONPATH so fitz resolves the way it does at
    # runtime instead of relying on the venv's implicit Homebrew .pth entries
    ENV["PYTHONPATH"] = [pymupdf_site_packages.join(":"), ENV["PYTHONPATH"]].reject { |p| p.to_s.empty? }.join(":")

    # Test Python module can be imported with PyMuPDF support
    system libexec/"bin/python", "-c", "import xray; from fitz import Document"

    # End-to-end: exercise the wrapper itself on a minimal PDF
    (testpath/"test.pdf").write <<~PDF
      %PDF-1.4
      1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
      2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
      3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]>>endobj
      trailer<</Root 1 0 R>>
      %%EOF
    PDF
    assert_match "{}", shell_output("#{bin/"x-ray"} #{testpath/"test.pdf"}")
  end
end
