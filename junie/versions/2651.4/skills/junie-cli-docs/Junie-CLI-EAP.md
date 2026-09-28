# Early Access Program (EAP)

<show-structure for="chapter" depth="2" />

The Early Access Program (EAP) gives you access to pre-release versions of Junie CLI with the latest features and improvements
before they are generally available.

> By participating in the EAP, you agree to the [JetBrains Junie Terms of Service](https://www.jetbrains.com/legal/docs/terms/jetbrains-junie/),
> including the EAP-specific terms. "EAP" means any of the pre-release versions of the product made available under these Terms
> as determined by JetBrains.
> {style="note"}

## Join the EAP {id="join-eap"}

The EAP is free to join and includes a monthly usage quota at no cost. To request access, fill out the [Contact Form](https://intellij-support.jetbrains.com/hc/en-us/requests/new?ticket_form_id=66731).

We are actively looking for developers working with the following languages and technologies:

- C and C++
- PHP
- Rust
- Java

If you work with any of these languages, we especially encourage you to apply.

## Install the Early Access version {id="install-eap"}

To install the Early Access version of Junie CLI, run the following command in your terminal:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install-eap.sh | bash</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://junie.jetbrains.com/install-eap.ps1')"</code-block>
    </tab>
</tabs>

To verify the installation, restart your shell if needed and run:

<code-block lang="Console">junie --version</code-block>


## Switch between EAP and stable versions {id="switch-versions"}

To switch back to the stable version, remove the local Junie launcher first:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">rm ~/.local/bin/junie</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">Remove-Item "$HOME\.local\bin\junie.bat"</code-block>
    </tab>
</tabs>

Then install the stable version using the standard installation command:

<tabs>
    <tab title="Linux / macOS">
        <code-block lang="Console">curl -fsSL https://junie.jetbrains.com/install.sh | bash</code-block>
    </tab>
    <tab title="Windows">
        <code-block lang="PowerShell">powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://junie.jetbrains.com/install.ps1')"</code-block>
    </tab>
</tabs>

For more details on the standard installation process, see the [Quickstart](Junie-CLI.md).
