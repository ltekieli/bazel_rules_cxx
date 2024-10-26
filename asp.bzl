def _impl(target, _):
    if InstrumentedFilesInfo in target:
        print(target[InstrumentedFilesInfo])
    return []
 
check_gcno = aspect(
    implementation = _impl,
    attr_aspects = [],
)
