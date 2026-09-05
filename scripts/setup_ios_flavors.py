#!/usr/bin/env python3
"""Wire dev/staging/prod Flutter iOS flavors into an Xcode project (P1-E-05).

Usage:
  python3 scripts/setup_ios_flavors.py mobile-rider ng.along.rider
  python3 scripts/setup_ios_flavors.py mobile-driver ng.along.driver
"""
from __future__ import annotations

import re
import sys
import uuid
from pathlib import Path

FLAVORS = ("dev", "staging", "prod")
MODES = ("Debug", "Release", "Profile")

# Stable Xcode object ids from the default Flutter ios template.
PROJECT_DEBUG = "97C147031CF9000F007C117D"
PROJECT_RELEASE = "97C147041CF9000F007C117D"
PROJECT_PROFILE = "249021D3217E4FDB00AE95B9"
RUNNER_DEBUG = "97C147061CF9000F007C117D"
RUNNER_RELEASE = "97C147071CF9000F007C117D"
RUNNER_PROFILE = "249021D4217E4FDB00AE95B9"
TESTS_DEBUG = "331C8088294A63A400263BE5"
TESTS_RELEASE = "331C8089294A63A400263BE5"
TESTS_PROFILE = "331C808A294A63A400263BE5"
LIST_PROJECT = "97C146E91CF9000F007C117D"
LIST_RUNNER = "97C147051CF9000F007C117D"
LIST_TESTS = "331C8087294A63A400263BE5"


def gen_id() -> str:
    return uuid.uuid4().hex[:24].upper()


def sentence_case(name: str) -> str:
    return name[0].upper() + name[1:] if name else name


def bundle_id(prefix: str, flavor: str) -> str:
    return prefix if flavor == "prod" else f"{prefix}.{flavor}"


def write_xcconfigs(ios_dir: Path, prefix: str) -> dict[tuple[str, str], Path]:
    flutter_dir = ios_dir / "Flutter"
    flutter_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[tuple[str, str], Path] = {}
    for flavor in FLAVORS:
        bid = bundle_id(prefix, flavor)
        for mode in MODES:
            base = "Release.xcconfig" if mode == "Profile" else f"{mode}.xconfig"
            if mode == "Profile":
                base = "Release.xcconfig"
            rel = flutter_dir / f"{flavor}{mode}.xcconfig"
            rel.write_text(
                f'#include "{base.replace(".xconfig", ".xcconfig")}"\n'
                f"PRODUCT_BUNDLE_IDENTIFIER={bid}\n",
                encoding="utf-8",
            )
            paths[(flavor, mode)] = rel
    return paths


def scheme_xml(flavor_title: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "97C146ED1CF9000F007C117D"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug-{flavor_title}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8080294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug-{flavor_title}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Profile-{flavor_title}"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug-{flavor_title}">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release-{flavor_title}"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def extract_object_block(text: str, object_id: str) -> str:
    marker = f"{object_id} /*"
    start = text.find(f"\t{object_id} /*")
    if start < 0:
        raise ValueError(f"Missing object {object_id}")
    depth = 0
    i = start
    while i < len(text):
        ch = text[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = text.find(";", i) + 1
                return text[start:end]
        i += 1
    raise ValueError(f"Unclosed object block for {object_id}")


def clone_block(block: str, new_id: str, new_name: str) -> str:
    out = re.sub(
        r"^\t[A-F0-9]+ /\* .+? \*/ = \{",
        f"\t{new_id} /* {new_name} */ = {{",
        block,
        count=1,
        flags=re.MULTILINE,
    )
    out = re.sub(r"\n\t\t\tname = .+?;", f"\n\t\t\tname = {new_name};", out, count=1)
    return out


def set_base_config(block: str, ref_id: str, ref_name: str) -> str:
    if "baseConfigurationReference" in block:
        return re.sub(
            r"baseConfigurationReference = [A-F0-9]+ /\* .+? \*/;",
            f"baseConfigurationReference = {ref_id} /* {ref_name} */;",
            block,
            count=1,
        )
    return block.replace(
        "\t\t\tbuildSettings = {",
        f"\t\t\tbaseConfigurationReference = {ref_id} /* {ref_name} */;\n\t\t\tbuildSettings = {{",
        1,
    )


def strip_bundle_id(block: str) -> str:
    return re.sub(r"\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = .+?;", "", block)


def set_tests_bundle_id(block: str, bundle: str) -> str:
    block = strip_bundle_id(block)
    return block.replace(
        "\t\t\tbuildSettings = {",
        f"\t\t\tbuildSettings = {{\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {bundle}.RunnerTests;",
        1,
    )


def replace_config_list(text: str, list_id: str, config_ids: list[str]) -> str:
    pattern = (
        rf"(\t{list_id} /\* Build configuration list.*?\n\t\t\tbuildConfigurations = \(\n)"
        rf"(.*?)"
        rf"(\t\t\t\);)"
    )

    def repl(match: re.Match[str]) -> str:
        entries = "\n".join(f"\t\t\t\t{id_} /* {id_} */," for id_ in config_ids)
        return match.group(1) + entries + "\n" + match.group(3)

    updated, count = re.subn(pattern, repl, text, count=1, flags=re.DOTALL)
    if count != 1:
        raise ValueError(f"Failed to update configuration list {list_id}")
    return updated


def patch_pbxproj(pbx_path: Path, prefix: str, xcconfig_paths: dict[tuple[str, str], Path]) -> None:
    text = pbx_path.read_text(encoding="utf-8")

    file_ref_entries: list[str] = []
    file_ref_ids: dict[tuple[str, str], str] = {}
    gs_id = gen_id()
    file_ref_entries.append(
        f"\t\t{gs_id} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = GoogleService-Info.plist; sourceTree = \"<group>\"; }};"
    )
    for (flavor, mode), path in xcconfig_paths.items():
        fid = gen_id()
        file_ref_ids[(flavor, mode)] = fid
        rel = path.relative_to(pbx_path.parent.parent)
        file_ref_entries.append(
            f"\t\t{fid} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = {path.name}; path = {rel.as_posix()}; sourceTree = \"<group>\"; }};"
        )

    text = text.replace(
        "/* End PBXFileReference section */",
        "\n".join(file_ref_entries) + "\n/* End PBXFileReference section */",
    )

    text = text.replace(
        "\t\t\t97C147021CF9000F007C117D /* Info.plist */,\n",
        f"\t\t\t97C147021CF9000F007C117D /* Info.plist */,\n\t\t\t{gs_id} /* GoogleService-Info.plist */,\n",
    )

    gs_build_id = gen_id()
    text = text.replace(
        "/* End PBXBuildFile section */",
        f"\t\t{gs_build_id} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {gs_id} /* GoogleService-Info.plist */; }};\n/* End PBXBuildFile section */",
    )
    text = text.replace(
        "97C146FC1CF9000F007C117D /* Main.storyboard in Resources */,\n",
        f"97C146FC1CF9000F007C117D /* Main.storyboard in Resources */,\n\t\t\t\t{gs_build_id} /* GoogleService-Info.plist in Resources */,\n",
    )

    flutter_children = [f"\t\t\t\t{fid} /* {flavor}{mode}.xcconfig */," for (flavor, mode), fid in file_ref_ids.items()]
    text = text.replace(
        "\t\t\t\t9740EEB31CF90195004384FC /* Generated.xcconfig */,\n",
        "\t\t\t\t9740EEB31CF90195004384FC /* Generated.xcconfig */,\n" + "\n".join(flutter_children) + "\n",
    )

    project_tpl = {
        "Debug": extract_object_block(text, PROJECT_DEBUG),
        "Release": extract_object_block(text, PROJECT_RELEASE),
        "Profile": extract_object_block(text, PROJECT_PROFILE),
    }
    runner_tpl = {
        "Debug": extract_object_block(text, RUNNER_DEBUG),
        "Release": extract_object_block(text, RUNNER_RELEASE),
        "Profile": extract_object_block(text, RUNNER_PROFILE),
    }
    tests_tpl = {
        "Debug": extract_object_block(text, TESTS_DEBUG),
        "Release": extract_object_block(text, TESTS_RELEASE),
        "Profile": extract_object_block(text, TESTS_PROFILE),
    }

    prod_bid = bundle_id(prefix, "prod")
    text = re.sub(
        r"PRODUCT_BUNDLE_IDENTIFIER = ng\.along\.mobile(Rider|Driver)(\.RunnerTests)?;",
        lambda m: f"PRODUCT_BUNDLE_IDENTIFIER = {prod_bid}{'.RunnerTests' if m.group(2) else ''};",
        text,
    )

    new_blocks: list[str] = []
    project_ids = [PROJECT_DEBUG, PROJECT_RELEASE, PROJECT_PROFILE]
    runner_ids = [RUNNER_DEBUG, RUNNER_RELEASE, RUNNER_PROFILE]
    tests_ids = [TESTS_DEBUG, TESTS_RELEASE, TESTS_PROFILE]

    for flavor in FLAVORS:
        title = sentence_case(flavor)
        bid = bundle_id(prefix, flavor)
        for mode in MODES:
            cfg_name = f"{mode}-{title}"
            proj_id = gen_id()
            run_id = gen_id()
            test_id = gen_id()
            project_ids.extend([proj_id])
            runner_ids.extend([run_id])
            tests_ids.extend([test_id])

            proj_block = clone_block(project_tpl[mode], proj_id, cfg_name)
            new_blocks.append(proj_block)

            xc_id = file_ref_ids[(flavor, mode)]
            xc_name = xcconfig_paths[(flavor, mode)].name
            run_block = set_base_config(clone_block(runner_tpl[mode], run_id, cfg_name), xc_id, xc_name)
            run_block = strip_bundle_id(run_block)
            new_blocks.append(run_block)

            test_block = set_tests_bundle_id(clone_block(tests_tpl[mode], test_id, cfg_name), bid)
            new_blocks.append(test_block)

    text = text.replace(
        "/* End XCBuildConfiguration section */",
        "\n".join(new_blocks) + "\n/* End XCBuildConfiguration section */",
    )

    text = replace_config_list(text, LIST_PROJECT, project_ids)
    text = replace_config_list(text, LIST_RUNNER, runner_ids)
    text = replace_config_list(text, LIST_TESTS, tests_ids)

    pbx_path.write_text(text, encoding="utf-8")


def write_google_service_stub(runner_dir: Path, prefix: str, flavor: str = "staging") -> None:
    bid = bundle_id(prefix, flavor)
    runner_dir.mkdir(parents=True, exist_ok=True)
    path = runner_dir / "GoogleService-Info.plist"
    if path.exists():
        return
    path.write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CLIENT_ID</key>
\t<string>stub-client-id.apps.googleusercontent.com</string>
\t<key>REVERSED_CLIENT_ID</key>
\t<string>com.googleusercontent.apps.stub</string>
\t<key>API_KEY</key>
\t<string>AIzaStubCompileOnlyKey</string>
\t<key>GCM_SENDER_ID</key>
\t<string>000000000000</string>
\t<key>PLIST_VERSION</key>
\t<string>1</string>
\t<key>BUNDLE_ID</key>
\t<string>{bid}</string>
\t<key>PROJECT_ID</key>
\t<string>along-stub</string>
\t<key>STORAGE_BUCKET</key>
\t<string>along-stub.appspot.com</string>
\t<key>IS_ADS_ENABLED</key>
\t<false/>
\t<key>IS_ANALYTICS_ENABLED</key>
\t<false/>
\t<key>IS_APPINVITE_ENABLED</key>
\t<true/>
\t<key>IS_GCM_ENABLED</key>
\t<true/>
\t<key>IS_SIGNIN_ENABLED</key>
\t<true/>
\t<key>GOOGLE_APP_ID</key>
\t<string>1:000000000000:ios:0000000000000000000000</string>
</dict>
</plist>
""",
        encoding="utf-8",
    )


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        sys.exit(1)
    app_dir = Path(sys.argv[1])
    prefix = sys.argv[2]
    ios_dir = app_dir / "ios"
    if not ios_dir.is_dir():
        sys.exit(f"Missing {ios_dir}")

    xcconfigs = write_xcconfigs(ios_dir, prefix)
    write_google_service_stub(ios_dir / "Runner", prefix)
    patch_pbxproj(ios_dir / "Runner.xcodeproj" / "project.pbxproj", prefix, xcconfigs)

    schemes_dir = ios_dir / "Runner.xcodeproj" / "xcshareddata" / "xcschemes"
    schemes_dir.mkdir(parents=True, exist_ok=True)
    for flavor in FLAVORS:
        title = sentence_case(flavor)
        (schemes_dir / f"{title}.xcscheme").write_text(scheme_xml(title), encoding="utf-8")

    print(f"Configured iOS flavors for {app_dir} ({prefix})")


if __name__ == "__main__":
    main()
