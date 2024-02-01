fn main() {
    let languages = ["c", "rust"];

    for language in languages {
        let package = format!("tree-sitter-{}", language);
        let source_directory = format!("{}/src", package);
        let source_file = format!("{}/parser.c", source_directory);
        let scanner_file = format!("{}/scanner.c", source_directory);

        println!("cargo:rerun-if-changed={}", source_file);

        let mut build = cc::Build::new();
        let mut build = build.opt_level(3)
            .warnings(false)
            .include(source_directory)
            .file(source_file);

        if let Ok(_) = std::fs::File::open(&scanner_file[..]) {
            build = build.file(scanner_file);
        }

        build.compile(&package);
    }
}
