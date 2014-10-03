#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vi:et:sw=4 ts=4
# Copyright (C) 2014 Puneeth Nanjundaswamy <puneeth@netapp.com>
#
# CONFIGURATION SECTION
url = 'www.alexa.com'
#
#
#
#
#
#
#
# Beautifulsoup imports
from bs4 import BeautifulSoup

# python imports
import argparse
import requests
import textwrap
import re


class FetchData():
    """ This class has various functions that can be used to fetch data from
        Alexa"""

    def __init__(self):
        """Constructor of the object"""
        description = textwrap.dedent("""crawl Alexa to fetch top websites in
                                      one/all categories.""")

        self.parser = argparse.ArgumentParser(description=description)

        self.parser.add_argument("-c", "--category", choices=['country',
                                                              'category',
                                                              'top_sites',
                                                              'all'],
                                 required=True, metavar='CATEGORY',
                                 action="store", help="%(choices)s")

        self.parser.add_argument("-s", "--sub_category",
                                 metavar='SUB-CATEGORY', action="store",
                                 help="Ex: country codes,\
                                 Games, Arts, Business")

        self.url = url
        self.resource = None
        self.cc = False
        self.regX = re.compile('^a')

    def parse_options(self, args=None):
        """Parse options for generic Application object"""

        # parse options
        self.args = self.parser.parse_args(args)

    def apply_options(self):
        """Configure generic Application object based on the options from
        the argparser"""
        if 'top_sites' in self.args.category:
            self.resource = "/topsites/"

        elif 'all' in self.args.category:
            raise NotImplementedError("To be implemented!")

        elif 'country' in self.args.category:
            self.resource = "/topsites/countries/"
            if not self.args.sub_category or len(self.args.sub_category) != 2:
                self.cc = True
                print ('No/Invalid country code provided.\
                       Fetching valid country codes\n')
                soup = self.fetch_data(self.url+self.resource)
                self.parse_data(soup, self.resource)
                exit(1)

            self.args.sub_category = self.args.sub_category.upper()
            self.resource += self.args.sub_category

        elif 'category' in self.args.category:
            self.resource = "/topsites/category/Top/"
            if not self.args.sub_category:
                print ('No sub-category provided. Fetching categories\n')
                soup = self.fetch_data(self.url + self.resource)
                self.parse_data(soup, self.resource)
                exit(1)

            self.resource += self.args.sub_category

    def fetch_data(self, url):
        r = requests.get("http://" + url)
        data = r.text
        return BeautifulSoup(data)

    def parse_data(self, soup, string):
        if not self.cc:
            for link in soup.find_all(self.regX):
                if (link.get('href') is not None) and \
                        (string in link.get('href')):
                    print (link.get('href')).replace(string, '')
        else:
            for link in soup.find_all(self.regX):
                if (link.get('href') is not None) and\
                        (string in link.get('href')):
                    print (link.string).strip() + ' = ' \
                        + (link.get('href')).replace(string, '')

    def run(self):
        while True:
            soup = self.fetch_data(self.url + self.resource)
            self.parse_data(soup, '/siteinfo/')

            if not len(soup.find_all(title='Next')):
                break

            for link in soup.find_all(title='Next'):
                self.resource = link.get('href')

    def main(self):
        self.parse_options()
        self.apply_options()
        self.run()

if __name__ == "__main__":
    FetchData().main()
