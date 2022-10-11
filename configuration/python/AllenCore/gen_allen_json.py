if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument(
        "--no-register-keys",
        action="store_false",
        dest="register_keys",
        default=True)
    parser.add_argument(
        "--seqpath",
        dest="seqpath",
        default="")
    args = parser.parse_args()
    
    from AllenCore.configuration_options import is_allen_standalone
    is_allen_standalone.global_bind(standalone=True)

    from AllenCore.configuration_options import allen_register_keys
    allen_register_keys.global_bind(register_keys=args.register_keys)

    import importlib.util
    import sys
    spec = importlib.util.spec_from_file_location("allen_sequence", args.seqpath)
    foo = importlib.util.module_from_spec(spec)
    sys.modules["allen_sequence"] = foo
    spec.loader.exec_module(foo)
