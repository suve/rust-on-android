package pl.svgames.blog.RustOnAndroid;

import pl.svgames.blog.RustOnAndroid.Result;

public class RpnCalculator {
	// Used to load the 'native-lib' library on application startup.
	static {
		System.loadLibrary("rpn");
	}

	public static native Result rpn(String expression);
}
