mod lib;
use lib::*;

use std::io::{self, BufRead};

fn main() {
	let stdin = io::stdin();
	for line in stdin.lock().lines() {
		match rpn(&line.unwrap()) {
			Ok(answer) => println!("= {}", answer.as_str()),
			Err(e) => println!("{:?}", e),
		}
	}
}
