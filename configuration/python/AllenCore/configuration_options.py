class AllenConfigurationOptions:
    def __init__(self):
        from optparse import OptionParser
        parser = OptionParser()
        parser.add_option("--standalone", dest="standalone", default="0")
        parser.add_option("--register-keys", dest="register_keys", default="1")
        (options, _) = parser.parse_args()
        self.standalone = options.standalone == "1"
        self.register_keys = options.register_keys == "1"


allen_configuration_options = AllenConfigurationOptions()
