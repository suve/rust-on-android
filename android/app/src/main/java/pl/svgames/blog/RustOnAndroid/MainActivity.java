package pl.svgames.blog.RustOnAndroid;

import androidx.appcompat.app.AppCompatActivity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {
	private Button button;
	private EditText input;
	private TextView resultBox;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);

		button = (Button)findViewById(R.id.button);
		input = (EditText)findViewById(R.id.exprInput);
		resultBox = (TextView)findViewById(R.id.exprResult);

		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) {
				String expr = input.getText().toString();
				resultBox.setText(expr);
			}
		});
	}
}
