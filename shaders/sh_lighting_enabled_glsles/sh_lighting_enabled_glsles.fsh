// This shader tests the gm_LightingEnabled built-in uniform by outputting white if its true and black if its false
// Fragment Shader

// Input values
varying vec4 v_vColour;


void main()
{
	// Set the fragment colour to the vertex colour
	gl_FragColor = v_vColour;
}