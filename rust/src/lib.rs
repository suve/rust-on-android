#[cfg(target_os = "android")]
#[path = "android.rs"]
mod android;

use std::fmt::{Debug, Display, Error as FmtError, Formatter};
use std::vec::Vec;

use gmp::mpz::Mpz;
use thiserror::Error as DeriveError;

#[derive(DeriveError, Debug)]
pub enum RpnError {
	FailedToParseNumber,
	NotEnoughOperands,
	NotEnoughOperators,
	Unknown,
}

impl Display for RpnError {
	fn fmt(&self, f: &mut Formatter) -> Result<(), FmtError> {
		write!(f, "{:?}", self)
	}
}

pub struct BigNum {
	strval: String,
	intval: Option<i64>,
}

impl BigNum {
	fn new(value: Mpz) -> Self {
		let strval = value.to_str_radix(10);
		let intval = match str::parse::<i64>(&strval) {
			Ok(v) => Some(v),
			Err(_) => None,
		};

		Self { strval, intval }
	}

	pub fn as_i64(&self) -> Option<i64> {
		self.intval
	}

	pub fn as_str(&self) -> &str {
		&self.strval
	}
}

impl Display for BigNum {
	fn fmt(&self, f: &mut Formatter) -> Result<(), FmtError> {
		write!(f, "{}", self.strval)
	}
}

pub fn rpn(text: &str) -> Result<BigNum, RpnError> {
	let mut values: Vec<Mpz> = vec![];

	for part in text.split_ascii_whitespace() {
		match part {
			"+" | "-" | "*" | "/" | "%" => {
				if values.len() < 2 {
					return Err(RpnError::NotEnoughOperands);
				}
				let b = values.pop().unwrap();
				let a = values.pop().unwrap();

				let new = match part {
					"+" => a + b,
					"-" => a - b,
					"*" => a * b,
					"/" => a / b,
					"%" => a % b,
					_ => return Err(RpnError::Unknown),
				};
				values.push(new);
			}
			_ => match Mpz::from_str_radix(part, 10) {
				Ok(v) => values.push(v),
				Err(_) => return Err(RpnError::FailedToParseNumber),
			},
		}
	}

	match values.len() {
		0 => Err(RpnError::NotEnoughOperands),
		1 => Ok(BigNum::new(values.pop().unwrap())),
		_ => Err(RpnError::NotEnoughOperators),
	}
}
